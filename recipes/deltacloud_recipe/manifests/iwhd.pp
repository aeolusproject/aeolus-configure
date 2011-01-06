# Deltacloud iwhd puppet definitions

class deltacloud::iwhd inherits deltacloud {
  ### Start the deltacloud services
    file { "/data":    ensure => 'directory' }
    file { "/data/db": ensure => 'directory' }
    service { 'mongod':
      ensure  => 'running',
      enable  => true,
      require => [Package['iwhd'], File["/data/db"]]}
    service { 'iwhd':
      ensure  => 'running',
      enable  => true,
      require => [Package['iwhd'],
                  Service[mongod]]}
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
}

# Create a named bucket in iwhd
define deltacloud::create_bucket(){
  package{'curl': ensure => 'installed'}
  # XXX ugly hack but iwhd might take some time to come up
  exec{"iwhd_startup_pause":
              command => "/bin/sleep 2",
              require => Service[iwhd]}
  exec{"create-bucket-${name}":
         command => "/usr/bin/curl -X PUT http://localhost:9090/templates",
         require => [Exec['iwhd_startup_pause'], Package[curl]] }
}
