#   Copyright 2011 Red Hat, Inc.
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.

# Aeolus conductor puppet definitions

class aeolus::conductor inherits aeolus {
  ### Install the aeolus components
    # specific versions of these two packages are needed and we need to pull the third in
    package {['aeolus-conductor',
              'aeolus-conductor-daemons',
              'aeolus-all']:
              ensure => 'installed',
              provider => $package_provider }

    file{"/usr/share/aeolus-conductor/config/settings.yml":
      content => template("aeolus/conductor-settings.yml"),
      require => Package['aeolus-conductor']}

    file{"/usr/share/aeolus-conductor/config/initializers/secret_token.rb":
      content => template("aeolus/secret_token.rb"),
      require => Package['aeolus-conductor']}

    file{"/rsyslog": ensure => 'directory' }
    file{"/rsyslog/work":
         ensure  => 'directory',
         require => File['/rsyslog'] }

    file{"/etc/rsyslog.d": ensure => 'directory' }
    file{"/etc/rsyslog.d/aeolus.conf":
      content => template("aeolus/rsyslog"),
      notify  => Service['rsyslog']}

    service { 'rsyslog':
        ensure  => 'running',
        enable  => true,
        require => File['/etc/rsyslog.d/aeolus.conf', '/rsyslog/work'] }

    file {"/var/lib/aeolus-conductor":
      ensure => directory,
      owner => 'aeolus',
      group => 'aeolus',
      require => Package['aeolus-conductor']}

  ### Setup apache for deltacloud
    include apache
    if $enable_https {
      apache::site{"aeolus-conductor": source => 'puppet:///modules/aeolus/aggregator-httpd-ssl.conf'}
    } else{
      apache::site{"aeolus-conductor": source => 'puppet:///modules/aeolus/aggregator-httpd.conf'}
    }

    service { ['aeolus-conductor',
               'conductor-dbomatic' ]:
      ensure    => 'running',
      enable    => true,
      hasstatus => true,
      require => [Package['aeolus-conductor-daemons'],
                  Rails::Migrate::Db[migrate_aeolus_database],
                  Service['httpd'],
                  Apache::Site[aeolus-conductor], Exec[reload-apache],
                  File['/usr/share/aeolus-conductor/config/settings.yml'],
                  File['/usr/share/aeolus-conductor/config/initializers/secret_token.rb']] }

  ### Initialize and start the aeolus database
    # Right now we configure and start postgres, at some point I want
    # to make the db that gets setup configurable
    include postgres::server
    if $enable_security {
      openssl::certificate{"/var/lib/pgsql/data/server":
               user    => 'postgres',
               group   => 'postgres',
               require => Exec["pginitdb"],
               notify  => Service['postgresql']}
      # since we're self signing for now, use the same certificate for the root
      file { "/var/lib/pgsql/data/root.crt":
               require => Openssl::Certificate["/var/lib/pgsql/data/server"],
               source => "/var/lib/pgsql/data/server.crt",
               owner   => 'postgres',
               group   => 'postgres',
               notify  => Service['postgresql'] }
      file { "/var/lib/pgsql/data/pg_hba.conf":
               source  => "puppet:///modules/aeolus/pg_hba-ssl.conf",
               require => Exec["pginitdb"],
               owner   => 'postgres',
               group   => 'postgres',
               notify  => Service['postgresql']}
      file { "/var/lib/pgsql/data/postgresql.conf":
               source  => "puppet:///modules/aeolus/postgresql.conf",
               require => Exec["pginitdb"],
               owner   => 'postgres',
               group   => 'postgres',
               notify  => Service['postgresql']}
    } else {
      file { "/var/lib/pgsql/data/pg_hba.conf":
               source => "puppet:///modules/aeolus/pg_hba.conf",
               require => Exec["pginitdb"],
               owner   => 'postgres',
               group   => 'postgres',
               notify  => Service['postgresql']}
    }
    postgres::user{"aeolus":
                     password => "v23zj59an",
                     roles    => "CREATEDB",
                     require  => [Service["postgresql"], File["/var/lib/pgsql/data/pg_hba.conf"]] }


    # Create aeolus database
    rails::create::db{"create_aeolus_database":
                cwd        => "/usr/share/aeolus-conductor",
                rails_env  => "production",
                require    => [Postgres::User[aeolus], Package['aeolus-conductor']] }
    rails::migrate::db{"migrate_aeolus_database":
                cwd             => "/usr/share/aeolus-conductor",
                rails_env       => "production",
                require         => [Rails::Create::Db[create_aeolus_database]]}
    rails::seed::db{"seed_aeolus_database":
                cwd             => "/usr/share/aeolus-conductor",
                rails_env       => "production",
                require         => Rails::Migrate::Db[migrate_aeolus_database]}

  ### Setup sshd for deltacloud
  package { "openssh-server": ensure => installed }
    service{"sshd":
             require  => Package["openssh-server"],
             ensure   =>  'running',
             enable  =>  'true' }
}

class aeolus::conductor::disabled {
    file {"/var/lib/aeolus-conductor":
            ensure => absent,
            force  => true
    }

    file {"/etc/rsyslog.d/aeolus.conf":
            ensure => absent,
            force  => true
    }

  ### Stop the aeolus services
    service { ['httpd']:
      ensure  => 'stopped',
      enable  => false,
      require => Service['aeolus-conductor',
                         'conductor-dbomatic'] }
    service { ['aeolus-conductor',
               'conductor-dbomatic']:
      ensure => 'stopped',
      enable => false,
      hasstatus => true }

  ### Destroy the aeolus database
    rails::drop::db{"drop_aeolus_database":
                cwd        => "/usr/share/aeolus-conductor",
                rails_env  => "production",
                require    => Service["aeolus-conductor",
                                      "conductor-dbomatic"]}
    postgres::user{"aeolus":
                    ensure => 'dropped',
                    require => Rails::Drop::Db["drop_aeolus_database"]}
}

# Create a new site admin conductor web user
define aeolus::conductor::site_admin($email="", $password="", $first_name="", $last_name=""){
  exec{"create_site_admin_user":
         cwd         => '/usr/share/aeolus-conductor',
         environment => "RAILS_ENV=production",
         command     => "/usr/bin/rake dc:create_user[${name},${password},${email},${first_name},${last_name}]",
         logoutput   => true,
         unless      => "/usr/bin/test `psql conductor aeolus -P tuples_only -c \"select count(*) from users where login = '${name}';\"` = \"1\"",
         require     => Rails::Seed::Db["seed_aeolus_database"]}
  exec{"grant_site_admin_privs":
         cwd         => '/usr/share/aeolus-conductor',
         environment => "RAILS_ENV=production",
         command     => "/usr/bin/rake dc:site_admin[${name}]",
         logoutput   => true,
         unless      => "/usr/bin/test `psql conductor aeolus -P tuples_only -c \"select count(*) FROM roles INNER JOIN permissions ON (roles.id = permissions.role_id) INNER JOIN users ON (permissions.user_id = users.id) where roles.name = 'Administrator' AND users.login = '${name}';\"` = \"1\"",
         require     => Exec[create_site_admin_user]}
}

# login to the aeolus conductor
define aeolus::conductor::login($password){
  web_request{ "$name-conductor-login":
    post         => 'https://localhost/conductor/user_session',
    parameters  => { 'login'    => "$name", 'password' => "$password",
                     'commit'                 => 'submit' },
    returns     => '200',
    follow      => true,
    store_cookies_at => "/tmp/aeolus-$name",
    require    => Service['aeolus-conductor']
  }
}

# log out of the aeolus conductor
define aeolus::conductor::logout(){
  web_request{ "$name-conductor-logout":
    post         => 'https://localhost/conductor/logout',
    parameters  => { 'login'    => "admin", 'password' => "password",
                     'commit'                 => 'submit' },
    returns     => '200',
    follow      => true,
    use_cookies_at => "/tmp/aeolus-$name",
    remove_cookies => true
  }
}

# Create a new provider via the conductor
define aeolus::conductor::provider($deltacloud_driver="",$url="", $deltacloud_provider=""){
  web_request{ "provider-$name":
    post         => "https://localhost/conductor/providers",
    parameters  => { 'provider[name]'  => $name, 'provider[url]'   => $url,
                     'provider[provider_type_deltacloud_driver]' => $deltacloud_driver,
                     'provider[deltacloud_provider]' => $deltacloud_provider },
    returns     => '200',
    follow      => true,
    contains    => "//html/body//li[text() = 'Provider added.']",
    use_cookies_at => '/tmp/aeolus-admin',
    unless      => { 'get'             => 'https://localhost/conductor/providers',
                     'contains'        => "//html/body//a[text() = '$name']" },
    require    => [Service['aeolus-conductor'], Exec['grant_site_admin_privs'], Exec['deltacloud-core-startup-wait']]
  }
}

# Create a new provider account via the conductor
define aeolus::conductor::provider::account($provider="", $type="", $username="",$password="", $account_id="",$x509private="", $x509public=""){
  if $type != "ec2" {
    web_request{ "provider-account-$name":
      post         => "https://localhost/conductor/providers/0/provider_accounts",
      parameters  => { 'provider_account[label]'  => $name,
                       'provider_account[provider]' => $provider,
                       'provider_account[credentials_hash[username]]'   => $username,
                       'provider_account[credentials_hash[password]]'   => $password,
                       'quota[max_running_instances]'   => 'unlimited',
                       'commit' => 'Save' },

      returns     => '200',
      #contains    => "//table/thead/tr/th[text() = 'Properties for $name']",
      follow      => true,
      use_cookies_at => '/tmp/aeolus-admin',
      unless      => { 'get'             => 'https://localhost/conductor/provider_accounts',
                       'contains'        => "//html/body//a[text() = '$name']" },
      require    => Service['aeolus-conductor']}

  } else {
    web_request{ "provider-account-$name":
      post         => "https://localhost/conductor/provider_accounts",
      parameters  => { 'provider_account[label]'  => $name,
                       'provider_account[provider]' => $provider,
                       'provider_account[credentials_hash[username]]'   => $username,
                       'provider_account[credentials_hash[password]]'   => $password,
                       'provider_account[credentials_hash[account_id]]' => $account_id,
                       'quota[max_running_instances]'   => 'unlimited',
                       'commit' => 'Save' },
      file_parameters  => { 'provider_account[credentials_hash[x509private]]'=> $x509private,
                            'provider_account[credentials_hash[x509public]]' => $x509public  },

      returns     => '200',
      #contains    => "//table/thead/tr/th[text() = 'Properties for $name']",
      follow      => true,
      use_cookies_at => '/tmp/aeolus-admin',
      unless      => { 'get'             => 'https://localhost/conductor/provider_accounts',
                       'contains'        => "//html/body//a[text() = '$name']" },
      require    => Service['aeolus-conductor']
    }
  }
}

define aeolus::conductor::hwp($memory='', $cpu='', $storage='', $architecture=''){
  web_request{ "hwp-$name":
    post         => "https://localhost/conductor/hardware_profiles",
    parameters  => {'hardware_profile[name]'  => $name,
                    'hardware_profile[memory_attributes][value]'       => $memory,
                    'hardware_profile[cpu_attributes][value]'          => $cpu,
                    'hardware_profile[storage_attributes][value]'      => $storage,
                    'hardware_profile[architecture_attributes][value]' => $architecture,
                    'hardware_profile[memory_attributes][name]'        => 'memory',
                    'hardware_profile[memory_attributes][unit]'        => 'MB',
                    'hardware_profile[cpu_attributes][name]'           => 'cpu',
                    'hardware_profile[cpu_attributes][unit]'           => 'count',
                    'hardware_profile[storage_attributes][name]'       => 'storage',
                    'hardware_profile[storage_attributes][unit]'       => 'GB',
                    'hardware_profile[architecture_attributes][name]'  => 'architecture',
                    'hardware_profile[architecture_attributes][unit]'  => 'label',
                    'commit' => 'Save'},
    returns     => '200',
    #verify      => '.*Hardware profile added.*',
    follow      => true,
    use_cookies_at => '/tmp/aeolus-admin',
    require    => [Service['aeolus-conductor'], Exec['grant_site_admin_privs']]
  }
}
