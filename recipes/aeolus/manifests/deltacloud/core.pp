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

    # Need to poll for deltacloud-core to complete startup
    # otherwise one may see connect issues when adding providers
    exec{"deltacloud-core-startup-wait":
      command     => "nc -z localhost 3002",
      tries       => 60,
      try_sleep   => 1,
      require     => Service["deltacloud-core"]}
}
