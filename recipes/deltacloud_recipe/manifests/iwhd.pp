# Deltacloud iwhd puppet definitions

class deltacloud::iwhd inherits deltacloud {
  ### Install the deltacloud components
    package { 'iwhd':
               provider => 'yum', ensure => 'installed',
               require => Yumrepo['deltacloud_arch', 'deltacloud_noarch']
               }

  ### Start the deltacloud services
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
      hasstatus => true,
      require => [File['/etc/rc.d/init.d/iwhd', '/etc/iwhd/conf.js'],
                  Package['iwhd'],
                  Service[mongod]]}

    # XXX ugly hack but iwhd might take some time to come up
    exec{"iwhd_startup_pause":
                command => "/bin/sleep 2",
                unless  => '/usr/bin/curl http://localhost:9090',
                require => Service[iwhd]}
}

class deltacloud::iwhd::disabled {
  ### Stop the deltacloud services
    service { 'mongod':
      ensure  => 'stopped',
      enable  => false,
      require => Service[iwhd]}
    service { 'iwhd':
      ensure  => 'stopped',
      enable  => false,
      hasstatus => true}


  ### Uninstall the deltacloud components
    package { 'iwhd':
                provider => 'yum', ensure => 'absent',
                require  => [Package['deltacloud-aggregator'], Service['iwhd']]}
}

# Create a named bucket in iwhd
define deltacloud::create_bucket(){
  package{'curl': ensure => 'installed'}
  exec{"create-bucket-${name}":
         command => "/usr/bin/curl -X PUT http://localhost:9090/templates",
         require => [Exec['iwhd_startup_pause'], Package[curl]] }
}

