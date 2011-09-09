# Aeolus deltacloud puppet definitions

class aeolus::deltacloud::core {
  ### Install the aeolus components
    include aeolus

    package { 'deltacloud-core':
              ensure => 'installed',
              provider => $package_provider }

  ### we need to sync time to communicate w/ cloud providers
    include ntp::client

  ### Start the aeolus services
    file { "/var/log/deltacloud-core": ensure => 'directory' }

    service { 'deltacloud-core':
      ensure => 'running',
      enable => true,
      hasstatus => true,
      require => [Package['deltacloud-core'], File["/var/log/deltacloud-core"]]}
}

class aeolus::deltacloud::ec2 {
  ### Install the driver-specific components
   # install ec2 support,
   package { "rubygem-aws":
                ensure => 'installed',
                provider => $package_provider }
}

class aeolus::deltacloud::disabled {
  ### Stop the aeolus services
    service { 'deltacloud-core':
      ensure  => 'stopped',
      enable  => false,
      hasstatus => true}
}
