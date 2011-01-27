# Aeolus deltacloud puppet definitions

class aeolus::deltacloud inherits aeolus {
  ### Install the aeolus components
    if $enable_packages {
      package { 'rubygem-deltacloud-core':
                  provider => 'yum', ensure => 'installed', require => Yumrepo['aeolus_arch', 'aeolus_noarch']}


      # install ec2 support,
      # TODO eventually we should prompt the user to select which drivers they want to install
      package { "rubygem-aws":
                   provider => 'yum', ensure => 'installed' }
    }
    file { "/var/log/deltacloud-core": ensure => 'directory' }

  ### we need to sync time to communicate w/ cloud providers
    include ntp::client

  ### Start the aeolus services
    file {"/etc/init.d/deltacloud-core":
           source => "puppet:///modules/aeolus_recipe/deltacloud-core",
           mode   => 755 }
    service { 'deltacloud-core':
       ensure  => 'running',
       enable  => true,
       require => [return_if($enable_packages, Package['rubygem-deltacloud-core', 'rubygem-aws']),
                   File['/etc/init.d/deltacloud-core', '/var/log/deltacloud-core']] }
}

class aeolus::deltacloud::disabled {
  ### Uninstall the aeolus components
    if $enable_packages {
      package { 'rubygem-deltacloud-core':
                  provider => 'yum', ensure => 'absent',
                  require  => Service['deltacloud-core']}
      package { "rubygem-aws":
                  provider => 'yum', ensure => 'absent',
                  require  => Service['deltacloud-core']}
    }

  ### Stop the aeolus services
    service { 'deltacloud-core':
      ensure  => 'stopped',
      enable  => false,
      hasstatus => true}
}

