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
    aeolus::rails::create::db{"create_aeolus_database":
                cwd        => "/usr/share/aeolus-conductor",
                rails_env  => "production",
                require    => [Postgres::User[aeolus], Package['aeolus-conductor']] }
    aeolus::rails::migrate::db{"migrate_aeolus_database":
                cwd             => "/usr/share/aeolus-conductor",
                rails_env       => "production",
                require         => [Aeolus::Rails::Create::Db[create_aeolus_database]]}
    aeolus::rails::seed::db{"seed_aeolus_database":
                cwd             => "/usr/share/aeolus-conductor",
                rails_env       => "production",
                require         => Aeolus::Rails::Migrate::Db[migrate_aeolus_database]}

    # Create default admin user
    aeolus::conductor::site_admin{"admin":
                    email => 'root@localhost.localdomain',
                    password => "password",
                    first_name => 'Administrator',
                    last_name => ''}

 ### Setup sshd for deltacloud
  package { "openssh-server": ensure => installed }
    service{"sshd":
             require  => Package["openssh-server"],
             ensure   =>  'running',
             enable  =>  'true' }
}
