# Deltacloud aggregator puppet definitions

class deltacloud::aggregator inherits deltacloud {
  ### Install the deltacloud components
    # specific versions of these two packages are needed and we need to pull the third in
     package { 'rubygem-deltacloud-client':
                 provider => 'yum', ensure => 'installed' }

     package {['deltacloud-aggregator',
               'deltacloud-aggregator-daemons',
               'deltacloud-aggregator-doc']:
               provider => 'yum', ensure => 'installed',
               require  => Package['rubygem-deltacloud-client',
                                   'rubygem-deltacloud-image-builder-agent',
                                   'iwhd']}

  ### Setup selinux for deltacloud
    selinux::mode{"permissive":}

  ### Setup firewall for deltacloud
    firewall::rule{"http": destination_port => '80'}

  ### Start the deltacloud services
    file {"/var/lib/condor/condor_config.local":
           source => "puppet:///modules/deltacloud_recipe/condor_config.local",
           require => Package['deltacloud-aggregator-daemons'] }
    service { ['condor', 'httpd']:
      ensure  => 'running',
      enable  => true,
      require => File['/var/lib/condor/condor_config.local'] }
    service { ['deltacloud-aggregator',
               'deltacloud-condor_refreshd',
               'deltacloud-dbomatic']:
      ensure    => 'running',
      enable    => true,
      hasstatus => true,
      require => [Package['deltacloud-aggregator-daemons'],
                  Rails::Migrate::Db[migrate_deltacloud_database],
                  Service[condor]] }

  ### Initialize and start the deltacloud database
    # Right now we configure and start postgres, at some point I want
    # to make the db that gets setup configurable
    include postgres::server
    file { "/var/lib/pgsql/data/pg_hba.conf":
             source => "puppet:///modules/deltacloud_recipe/pg_hba.conf",
             require => Exec["pginitdb"] }
    postgres::user{"dcloud":
                     password => "v23zj59an",
                     roles    => "CREATEDB",
                     require  => Service["postgresql"]}


    # Create deltacloud database
    rails::create::db{"create_deltacloud_database":
                cwd        => "/usr/share/deltacloud-aggregator",
                rails_env  => "production",
                require    => [Postgres::User[dcloud], Package['deltacloud-aggregator']]}
    rails::migrate::db{"migrate_deltacloud_database":
                cwd             => "/usr/share/deltacloud-aggregator",
                rails_env       => "production",
                require         => Rails::Create::Db[create_deltacloud_database]}
}

class deltacloud::aggregator::disabled {
  ### Uninstall the deltacloud components
    package {['deltacloud-aggregator-daemons',
              'deltacloud-aggregator-doc']:
              provider => 'yum', ensure => 'absent',
              require  => Service['deltacloud-aggregator',
                                  'deltacloud-condor_refreshd',
                                  'deltacloud-dbomatic',
                                  'imagefactoryd',
                                  'deltacloud-image_builder_service']}

    package {'deltacloud-aggregator':
              provider => 'yum', ensure => 'absent',
              require  => [Package['deltacloud-aggregator-daemons',
                                   'deltacloud-aggregator-doc'],
                           Rails::Drop::Db["drop_deltacloud_database"]] }

    package { 'rubygem-deltacloud-client':
                provider => 'yum', ensure => 'absent',
                require  => Package['deltacloud-aggregator']}

  ### Stop the deltacloud services
    service { ['condor', 'httpd']:
      ensure  => 'stopped',
      enable  => false,
      require => Service['deltacloud-aggregator',
                         'deltacloud-condor_refreshd',
                         'deltacloud-dbomatic'] }
    service { ['deltacloud-aggregator',
               'deltacloud-condor_refreshd',
               'deltacloud-dbomatic']:
      ensure => 'stopped',
      enable => false,
      hasstatus => true }

  ### Destroy the deltacloud database
    rails::drop::db{"drop_deltacloud_database":
                cwd        => "/usr/share/deltacloud-aggregator",
                rails_env  => "production",
                require    => Service["deltacloud-aggregator",
                                      "deltacloud-condor_refreshd",
                                      "deltacloud-dbomatic",
                                      "deltacloud-image_builder_service"]}
    postgres::user{"dcloud":
                    ensure => 'dropped',
                    require => Rails::Drop::Db["drop_deltacloud_database"]}
}

# Create a new site admin aggregator web user
define deltacloud::site_admin($email="", $password="", $first_name="", $last_name=""){
  exec{"create_site_admin_user":
         cwd         => '/usr/share/deltacloud-aggregator',
         environment => "RAILS_ENV=production",
         command     => "/usr/bin/rake dc:create_user[${name}] email=${email} password=${password} first_name=${first_name} last_name=${last_name}",
         unless      => "/usr/bin/test `psql dcloud dcloud -P tuples_only -c \"select count(*) from users where login = '${name}';\"` = \"1\"",
         require     => Rails::Migrate::Db["migrate_deltacloud_database"]}
  exec{"grant_site_admin_privs":
         cwd         => '/usr/share/deltacloud-aggregator',
         environment => "RAILS_ENV=production",
         command     => "/usr/bin/rake dc:site_admin[${name}]",
         unless      => "/usr/bin/test `psql dcloud dcloud -P tuples_only -c \"select count(*) FROM roles INNER JOIN permissions ON (roles.id = permissions.role_id) INNER JOIN users ON (permissions.user_id = users.id) where roles.name = 'Administrator' AND users.login = '${name}';\"` = \"1\"",
         require     => Exec[create_site_admin_user]}
}
