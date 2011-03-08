# aeolus iwhd puppet definitions

class aeolus::iwhd inherits aeolus {
  ### Install the deltacloud components
    if $enable_packages{
      package { 'iwhd':
                 provider => 'yum', ensure => 'installed',
                 require => Yumrepo['aeolus_arch', 'aeolus_noarch']
                 }
    }

  ### Start the aeolus services
    file { "/data":    ensure => 'directory' }
    file { "/data/db": ensure => 'directory' }
    file { "/etc/iwhd": ensure => 'directory'}
    file { "/etc/iwhd/conf.js":
           source => "puppet:///modules/aeolus_recipe/iwhd-conf.js",
           mode   => 755, require => File['/etc/iwhd'] }

     #TODO The service wrapper should probably be in the rpm itself
     file { "/etc/rc.d/init.d/iwhd":
            source => "puppet:///modules/aeolus_recipe/iwhd.init",
            mode   => 755 }

    service { 'mongod':
      ensure  => 'running',
      enable  => true,
      require => [return_if($enable_packages, Package['iwhd']), File["/data/db"]]}

    service { 'iwhd':
      ensure  => 'running',
      enable  => true,
      hasstatus => true,
      require => [File['/etc/rc.d/init.d/iwhd', '/etc/iwhd/conf.js'],
                  return_if($enable_packages, Package['iwhd']),
                  Service[mongod]]}

    # XXX ugly hack but iwhd might take some time to come up
    exec{"iwhd_startup_pause":
                command => "/bin/sleep 2",
                unless  => '/usr/bin/curl http://localhost:9090',
                logoutput => true,
                require => Service['iwhd']}
}

class aeolus::iwhd::disabled {
  ### Stop the aeolus services
    service { 'mongod':
      ensure  => 'stopped',
      enable  => false,
      require => Service[iwhd]}

    service { 'iwhd':
      ensure  =>  'stopped',
      enable  =>  false,
      hasstatus =>  true}

  ### Uninstall the aeolus components
    if $enable_packages {
      package { 'iwhd':
                  provider => 'yum', ensure => 'absent',
                  require  => [Package['aeolus-conductor'], Service['iwhd']]}
    }
}

# Create a named bucket in iwhd
define aeolus::create_bucket(){
  package{'curl': ensure => 'installed'}
  exec{"create-bucket-${name}":
         command => "/usr/bin/curl -X PUT http://localhost:9090/templates",
         logoutput => true,
         require => [Exec['iwhd_startup_pause'], Package[curl]] }
}

