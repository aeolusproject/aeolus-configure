# Deltacloud core puppet definitions

class deltacloud::core inherits deltacloud {
  ### Install the deltacloud components
    if $enable_packages {
      package { 'rubygem-deltacloud-core':
                  provider => 'yum', ensure => 'installed', require => Yumrepo['deltacloud_arch', 'deltacloud_noarch']}
    }
    file { "/var/log/deltacloud-core": ensure => 'directory' }

  ### we need to sync time to communicate w/ cloud providers
    include ntp::client

  ### Start the deltacloud services
    file {"/etc/init.d/deltacloud-core":
           source => "puppet:///modules/deltacloud_recipe/deltacloud-core",
           mode   => 755 }
    service { 'deltacloud-core':
       ensure  => 'running',
       enable  => true,
       require => [return_if($enable_packages, Package['rubygem-deltacloud-core']),
                   File['/etc/init.d/deltacloud-core', '/var/log/deltacloud-core']] }
}

class deltacloud::core::disabled {
  ### Uninstall the deltacloud components
    if $enable_packages {
      package { 'rubygem-deltacloud-core':
                  provider => 'yum', ensure => 'absent',
                  require  => Service['deltacloud-core']}
    }

  ### Stop the deltacloud services
    service { 'deltacloud-core':
      ensure  => 'stopped',
      enable  => false,
      hasstatus => true}
}

