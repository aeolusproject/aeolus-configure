# aeolus iwhd puppet definitions

class aeolus::iwhd inherits aeolus {
  ### Install the deltacloud components
  package { 'iwhd':
             ensure => 'installed' }

  package { 'mongodb-server':
             ensure => 'installed' }

  ### Start the aeolus services
    file { "/data":    ensure => 'directory' }
    file { "/data/db": ensure => 'directory' }
    file { "/etc/iwhd": ensure => 'directory'}
    file { "/var/lib/iwhd":  ensure => 'directory' }

    service { 'mongod':
      ensure  => 'running',
      enable  => true,
      require => [Package['mongodb-server'], File["/data/db"]]}

    service { 'iwhd':
      ensure  => 'running',
      enable  => true,
      hasstatus => true,
      require => [Package['iwhd'],
                  Service[mongod],
                  File['/var/lib/iwhd']]}

    # XXX ugly hack but iwhd might take some time to come up
    exec{"iwhd_startup_pause":
                command => "/bin/sleep 2",
                unless  => "/usr/bin/curl --proxy '' http://localhost:9090",
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

   file { "/var/lib/iwhd":
      ensure  => 'absent',
      backup => 'false',
      force   => true,
      require => Service['iwhd']}

}

# Create a named bucket in iwhd
define aeolus::create_bucket(){
  exec{"create-bucket-${name}":
         command => "/usr/bin/curl --proxy '' -X PUT http://localhost:9090/templates",
         logoutput => true,
         require => [Exec['iwhd_startup_pause'], Package[curl]] }
}

