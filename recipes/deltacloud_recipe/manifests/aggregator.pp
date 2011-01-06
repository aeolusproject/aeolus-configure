# Deltacloud aggregator puppet definitions

class deltacloud::aggregator inherits deltacloud {
  ### Install the deltacloud components
    # specific versions of these two packages are needed and we need to pull the third in
    package { 'python-imgcreate':
               provider => 'rpm', ensure => installed,
               source   => 'http://repos.fedorapeople.org/repos/deltacloud/appliance/fedora-13/x86_64/python-imgcreate-031-1.fc12.1.x86_64.rpm'}
    package { 'livecd-tools':
               provider => 'rpm', ensure => installed,
               source   => 'http://repos.fedorapeople.org/repos/deltacloud/appliance/fedora-13/x86_64/livecd-tools-031-1.fc12.1.x86_64.rpm',
               require  => Package['python-imgcreate']}
    package { 'appliance-tools':
               provider => 'yum', ensure => installed,
               require  => Package["livecd-tools", "python-imgcreate"]}

    # TODO:  Fix me, find a better way to do this...
    # We need to also install this rpm from amazon
    package{"ec2-ami-tools":
            provider => "rpm",
            source => "http://s3.amazonaws.com/ec2-downloads/ec2-ami-tools.noarch.rpm",
            ensure => 'installed' }

     package { 'rubygem-deltacloud-client':
                 provider => 'yum', ensure => 'installed' }
     package { 'rubygem-deltacloud-image-builder-agent':
                 provider => 'yum', ensure => 'installed',
                 require  => Package['appliance-tools', 'livecd-tools', 'python-imgcreate', 'ec2-ami-tools']}
     package { 'iwhd':
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
              require  => Package['deltacloud-aggregator-daemons',
                                  'deltacloud-aggregator-doc'] }
    package { 'rubygem-deltacloud-client':
                provider => 'yum', ensure => 'absent',
                require  => Package['deltacloud-aggregator']}
    package { 'rubygem-deltacloud-image-builder-agent':
                provider => 'yum', ensure => 'absent',
                require  => Package['deltacloud-aggregator']}
    package { 'iwhd':
                provider => 'yum', ensure => 'absent',
                require  => [Package['deltacloud-aggregator'], Service['iwhd']]}

    # FIXME these lingering dependencies, pulled in for
    # rubygem-deltacloud-image-builder-agent, need to be removed as
    # ec2-ami-tools and appliance-tools depend on them and using
    # 'absent' in the context of the 'yum' provider dispatches
    # to 'rpm -e' instead of 'yum erase'
    package { ['rubygem-boxgrinder-build-ec2-platform-plugin',
               'rubygem-boxgrinder-build-centos-os-plugin',
               'rubygem-boxgrinder-build-fedora-os-plugin']:
               provider => "yum", ensure => 'absent',
               require  => Package['rubygem-deltacloud-image-builder-agent']}
    package { 'rubygem-boxgrinder-build-rhel-os-plugin':
               provider => "yum", ensure => 'absent',
               require  => Package['rubygem-boxgrinder-build-centos-os-plugin']}
    package { 'rubygem-boxgrinder-build-rpm-based-os-plugin':
               provider => "yum", ensure => 'absent',
               require  => Package['rubygem-boxgrinder-build-rhel-os-plugin',
                                   'rubygem-boxgrinder-build-fedora-os-plugin']}

    package { 'ec2-ami-tools':
               provider => "yum", ensure => 'absent',
               require  => Package['rubygem-boxgrinder-build-ec2-platform-plugin']}
    package { 'appliance-tools':
               provider => 'yum', ensure => 'absent',
               require  => Package['rubygem-boxgrinder-build-rpm-based-os-plugin']}
    package { 'livecd-tools':
               provider => 'yum', ensure => 'absent',
               require  => Package['appliance-tools']}
    package { 'python-imgcreate':
               provider => 'yum', ensure => 'absent',
               require  => Package['appliance-tools', 'livecd-tools']}


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
