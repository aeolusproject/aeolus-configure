# Aeolus deltacloud puppet definitions

class aeolus::deltacloud::core {
  ### Install the aeolus components
    include aeolus

    if $enable_packages {
      package { 'rubygem-deltacloud-core':
                  provider => 'yum', ensure => 'installed', require => Yumrepo['aeolus_arch', 'aeolus_noarch']}
    }
}

# install the deltacloud component w/ the specified driver
define aeolus::deltacloud($provider_type="", $port="3002") {
  ### Install the driver-specific components
    $enable_ec2_packages = $enable_packages and $name == "ec2"
    if $enable_ec2_packages {
      # install ec2 support,
      package { "rubygem-aws":
                   provider => 'yum', ensure => 'installed' }
    }

  ### we need to sync time to communicate w/ cloud providers
    include ntp::client

  ### Start the aeolus services
    file { "/var/log/deltacloud-${name}": ensure => 'directory' }
    file {"/etc/init.d/deltacloud-${name}":
           content => template("aeolus_recipe/deltacloud-core"),
           mode   => 755 }
    service { "deltacloud-${name}":
       ensure  => 'running',
       enable  => true,
       require => [return_if($enable_packages, Package['rubygem-deltacloud-core']),
                   return_if($enable_ec2_packages, Package['rubygem-aws']),
                   File["/etc/init.d/deltacloud-${name}", "/var/log/deltacloud-${name}"]] }
}

define aeolus::deltacloud::disabled() {
  ### Uninstall the aeolus components
    if $enable_packages {
      package { 'rubygem-deltacloud-core':
                  provider => 'yum', ensure => 'absent',
                  require  => Service["deltacloud-${name}"]}
      package { "rubygem-aws":
                  provider => 'yum', ensure => 'absent',
                  require  => Service["deltacloud-${name}"]}
    }

  ### Stop the aeolus services
    service { "deltacloud-${name}":
      ensure  => 'stopped',
      enable  => false,
      hasstatus => true}
    file {"/etc/init.d/deltacloud-${name}":
      ensure => absent,
      require => Service["deltacloud-${name}"]}
}

