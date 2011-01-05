# Deltacloud puppet definitions

import "firewall"

import "postgres"
import "rails"
import "selinux"
import "time"

# Setup repos which to pull deltacloud components
define dc::repos(){
  yumrepo{"${name}_arch":
            name     => "${name}_arch",
            baseurl  => 'http://repos.fedorapeople.org/repos/deltacloud/appliance/fedora-$releasever/$basearch',
            enabled  => 1, gpgcheck => 0}
  yumrepo{"${name}_noarch":
            name     => "${name}_noarch",
            baseurl  => 'http://repos.fedorapeople.org/repos/deltacloud/appliance/fedora-$releasever/noarch',
            enabled  => 1, gpgcheck => 0}
  yumrepo{"${name}_pulp":
            name     => "${name}_pulp",
            baseurl  => 'http://repos.fedorapeople.org/repos/pulp/pulp/fedora-13/$basearch/',
            enabled  => 1, gpgcheck => 0}
}

# Install the deltacloud components
define dc::package::install(){
  case $name {
    'aggregator':  {
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
                   require  => Package['ec2-ami-tools']}
       package { 'iwhd':
                  provider => 'yum', ensure => 'installed' }


       package {['deltacloud-aggregator',
                 'deltacloud-aggregator-daemons',
                 'deltacloud-aggregator-doc']:
                 provider => 'yum', ensure => 'installed',
                 require  => Package['rubygem-deltacloud-client',
                                     'rubygem-deltacloud-image-builder-agent',
                                     'iwhd']}
    }

    'core': {
      package { 'rubygem-deltacloud-core':
                  provider => 'yum', ensure => 'installed'}
      file { "/var/log/deltacloud-core": ensure => 'directory' }
    }
  }
}

# Uninstall the deltacloud components
define dc::package::uninstall(){
  case $name {
    'aggregator':  {
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

       package { 'ec2-ami-tools':
                  provider => "yum", ensure => 'absent',
                  require  => Package['rubygem-boxgrinder-build-ec2-platform-plugin']}
    }

    'core': {
      package { 'rubygem-deltacloud-core':
                  provider => 'yum', ensure => 'absent',
                  require  => Service['deltacloud-core']}
    }
  }
}

# Setup selinux for deltacloud
define dc::selinux(){
  selinux::mode{"permissive":}
}

# Setup firewall for deltacloud
define dc::firewall(){
  firewall::setup{'deltacloud': status=>"enabled"}
  firewall_open_port{"httpd":   port => "80", policy => "tcp"}
}

# TODO disable selinux until we're sure everything works w/ it enabled

# Start the deltacloud services
define dc::service::start(){
  case $name {
    'aggregator':  {
      file {"/var/lib/condor/condor_config.local":
             source => "puppet:///deltacloud_recipe/condor_config.local",
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
    }

    'core':  {
      time::sync{"deltacloud":} # we need to sync time to communicate w/ cloud providers
      file {"/etc/init.d/deltacloud-core":
            source => "puppet:///deltacloud_recipe/deltacloud-core",
            mode   => 755 }
     service { 'deltacloud-core':
        ensure  => 'running',
        enable  => true,
        require => [Package['rubygem-deltacloud-core'],
                    File['/etc/init.d/deltacloud-core']] }
    }

    'iwhd':  {
      file { "/data":    ensure => 'directory' }
      file { "/data/db": ensure => 'directory' }
      file { "/etc/iwhd": ensure => 'directory'}
      file { "/etc/iwhd/conf.js":
             source => "puppet:///modules/deltacloud_recipe/iwhd-conf.js",
             mode   => 755, require => File['/etc/iwhd'] }

      #TODO The service wrapper should probably be in the rpm itself
      file { "/etc/rc.d/init.d/iwhd":
             source => "puppet:///modules/deltacloud_recipe/iwhd.init",
             mode   => 755 }

      service { 'mongod':
        ensure  => 'running',
        enable  => true,
        require => [Package['iwhd'], File["/data/db"]]}
      service { 'iwhd':
        ensure  => 'running',
        enable  => true,
        require => [File['/etc/rc.d/init.d/iwhd','/etc/iwhd/conf.js'],
                    Package['iwhd'],
                    Service[mongod]]}
    }

    'image-factory':  {
      dc::configure_boxgrinder{'conf_bxg':}
      file { "/etc/qpidd.conf":
                 source => "puppet:///deltacloud_recipe/qpidd.conf",
                 mode   => 644 }
      service {'qpidd':
                 ensure  => 'running',
                 enable  => true,
                 require => [File['/etc/qpidd.conf'],
                             Package['deltacloud-aggregator-daemons']]}
      file { "/etc/imagefactory.yml":
                 source => "puppet:///deltacloud_recipe/imagefactory.yml",
                 mode   => 644 }
      $requires = [Package['rubygem-deltacloud-image-builder-agent'],
                   Package['deltacloud-aggregator-daemons'],
                   File['/etc/imagefactory.yml'],
                   Service[qpidd],
                   Rails::Migrate::Db[migrate_deltacloud_database],
                   Dc::Configure_boxgrinder['conf_bxg']]
      service { 'imagefactoryd':
        ensure  => 'running',
        enable  => true,
        require => $requires}
      service { 'deltacloud-image_builder_service':
        ensure    => 'running',
        enable    => true,
        hasstatus => true,
        require   => $requires}
    }
  }
}

# Stop the deltacloud services
define dc::service::stop(){
  case $name {
    'aggregator':  {
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
    }

    'core':  {
      service { 'deltacloud-core':
        ensure  => 'stopped',
        enable  => false}
    }

    'iwhd':  {
      service { 'mongod':
        ensure  => 'stopped',
        enable  => false,
        require => Service[iwhd]}
      service { 'iwhd':
        ensure  => 'stopped',
        enable  => false}
    }

    'image-factory':  {
      service {'qpidd':
                 ensure  => 'stopped',
                 enable  => false,
                 require => Service['imagefactoryd', 'deltacloud-image_builder_service']}

      service { 'imagefactoryd':
        ensure  => 'stopped',
        enable  => false}

      service { 'deltacloud-image_builder_service':
          ensure  => 'stopped',
          hasstatus => true,
          enable  => false}
    }
  }
}

# Configure boxgrinder, this should go into the boxgrinder rpms eventually
define dc::configure_boxgrinder(){
  file { "/boxgrinder": ensure => "directory"}
  file { "/boxgrinder/appliances":
            ensure => "directory",
            require => File["/boxgrinder"]}
  file { "/boxgrinder/packaged_builders":
            ensure => "directory",
            require => File["/boxgrinder"]}
  file { "/root/.boxgrinder": ensure => "directory"}
  file { "/root/.boxgrinder/plugins":
            ensure => "directory",
            require => File["/root/.boxgrinder"]}
  file { "/root/.boxgrinder/plugins/local":
              source => "puppet:///deltacloud_recipe/root-boxgrinder-plugins-local",
              mode   => 644 }
}

# Configure pulp to fetch from Fedora
# TODO uncomment when factory/warehouse uses pulp
#exec{"pulp_fedora_config":
#      command => "/usr/bin/pulp-admin -u admin -p admin repo create --id=fedora-repo --feed yum:http://download.fedora.redhat.com/pub/fedora/linux/updates/13/x86_64/"
#}

# Create a named bucket in iwhd
define dc::create_bucket(){
  package{'curl': ensure => 'installed'}
  # XXX ugly hack but iwhd might take some time to come up
  exec{"iwhd_startup_pause":
              command => "/bin/sleep 2",
              require => Service[iwhd]}
  exec{"create-bucket-${name}":
         command => "/usr/bin/curl -X PUT http://localhost:9090/templates",
         require => [Exec['iwhd_startup_pause'], Package[curl]] }
}

# Initialize and start the deltacloud database
define dc::db(){
  # Right now we configure and start postgres, at some point I want
  # to make the db that gets setup configurable
  file { "/var/lib/pgsql/data/pg_hba.conf":
           source => "puppet:///deltacloud_recipe/pg_hba.conf",
           require => Postgres::Initialize[init_db] }
  postgres::initialize{'init_db':}
  postgres::start{'start_db': require => File["/var/lib/pgsql/data/pg_hba.conf"]}
  postgres::user{"dcloud":
                   password => "v23zj59an",
                   roles    => "CREATEDB",
                   require  => Postgres::Start[start_db]}


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

# Destroy the deltacloud database
define dc::db::destroy(){
  rails::drop::db{"drop_deltacloud_database":
              cwd        => "/usr/share/deltacloud-aggregator",
              rails_env  => "production",
              require    => Service["deltacloud-aggregator",
                                    "deltacloud-condor_refreshd",
                                    "deltacloud-dbomatic",
                                    "deltacloud-image_builder_service"]}
  postgres::user::remove{"dcloud": require => Rails::Drop::Db["drop_deltacloud_database"]}
}

# Create a new site admin aggregator web user
define dc::site_admin($email="", $password="", $first_name="", $last_name=""){
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

# Destroy and cleanup deltacloud artifacts
define dc::cleanup(){
  exec{"remove_deltacloud_templates": command => "/bin/rm -rf /templates"}
  exec{"remove_boxgrinder_dir":       command => "/bin/rm -rf /boxgrinder"}
}
