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
      require => Package['aeolus-conductor'],
      mode    => 640, owner => 'root', group => 'aeolus'}

    file{"/etc/ldap_fluff.yml":
      require => Package['aeolus-conductor'],
      mode    => 640, owner => 'root', group => 'aeolus'}

    file{"/etc/aeolus-conductor/secret_token":
      content => template("aeolus/secret_token"),
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
      apache::site {"aeolus-conductor": source => 'aeolus/aggregator-httpd-ssl.conf'}
    } else{
      apache::site {"aeolus-conductor": source => 'aeolus/aggregator-httpd.conf'}
    }

    service { ['aeolus-conductor',
               'conductor-dbomatic',
               'conductor-delayed_job']:
      ensure    => 'running',
      enable    => true,
      hasstatus => true,
      require => [Package['aeolus-conductor-daemons'],
                  Aeolus::Rails::Migrate::Db[migrate_aeolus_database],
                  Service['httpd'],
                  Apache::Site[aeolus-conductor], Exec[reload-apache],
                  File['/usr/share/aeolus-conductor/config/settings.yml'],
                  File['/etc/aeolus-conductor/secret_token']] }

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
      file { "/var/lib/pgsql/data/postgresql.conf":
               source  => "puppet:///modules/aeolus/postgresql.conf",
               require => Exec["pginitdb"],
               owner   => 'postgres',
               group   => 'postgres',
               notify  => Service['postgresql']}
    }
    exec{ "pgauthuser":
      command     => 'sed -i "s/host\(ssl\)*\(.*\)ident/host\1\2md5/" /var/lib/pgsql/data/pg_hba.conf',
      onlyif      => 'grep -r "host.*ident" /var/lib/pgsql/data/pg_hba.conf',
      require     => Exec["pginitdb"],
      notify      => Service["postgresql"]
    }
    postgres::user{"aeolus":
                     password => "v23zj59an",
                     roles    => "CREATEDB",
                     require  => Service["postgresql"] }


    # This gets generated on each invocation of db:migrate.  It is
    # possible that an old version with ownership root:root is still
    # around, which means that running db:migrate as the aeolus user
    # will fail since it cannot generate the new schema.  Make sure it
    # is owned by aeolus.
    file { "/usr/share/aeolus-conductor/db/schema.rb":
      ensure => present,
      owner  => aeolus,
      group  => aeolus
    }

    # Create aeolus database
    aeolus::rails::create::db{"create_aeolus_database":
                cwd        => "/usr/share/aeolus-conductor",
                rails_env  => "production",
                require    => [Postgres::User[aeolus], Exec['pgauthuser'], Package['aeolus-conductor']] }
    aeolus::rails::migrate::db{"migrate_aeolus_database":
                cwd             => "/usr/share/aeolus-conductor",
                rails_env       => "production",
                require         => [Aeolus::Rails::Create::Db[create_aeolus_database],
                                    File["/usr/share/aeolus-conductor/db/schema.rb"]]}
    aeolus::rails::seed::db{"seed_aeolus_database":
                cwd             => "/usr/share/aeolus-conductor",
                rails_env       => "production",
                require         => Aeolus::Rails::Migrate::Db[migrate_aeolus_database]}

    # Create default admin user
    include aeolus::profiles::common
    aeolus::conductor::destroy_temp_admins{ "before" : }
    aeolus::conductor::site_admin{"admin":
                    email => 'root@localhost.localdomain',
                    password => "password",
                    first_name => 'Administrator',
                    last_name => '',
                    require => Aeolus::Conductor::Destroy_temp_admins["before"]}

    Aeolus::Conductor::Site_admin <| |> -> Aeolus::Conductor::Temp_admin[$aeolus::profiles::common::temp_admin_login]

 ### Setup sshd for deltacloud
  package { "openssh-server": ensure => installed }
    service{"sshd":
             require  => Package["openssh-server"],
             ensure   =>  'running',
             enable  =>  'true' }
}
