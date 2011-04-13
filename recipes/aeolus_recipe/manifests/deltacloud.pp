# Aeolus deltacloud puppet definitions

class aeolus::deltacloud::core {
  ### Install the aeolus components
    include aeolus

    package { 'rubygem-deltacloud-core':
              ensure => 'installed', require => Yumrepo['aeolus_arch', 'aeolus_noarch']}
}

class aeolus::deltacloud::ec2 {
  ### Install the driver-specific components
   # install ec2 support,
   package { "rubygem-aws":
                ensure => 'installed' }
}


# install the deltacloud component w/ the specified driver
define aeolus::deltacloud($provider_type="", $port="3002") {
  include aeolus::deltacloud::core

  if $provider_type == "ec2" {
    include aeolus::deltacloud::ec2
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
       require => [Package['rubygem-deltacloud-core'],
                   Package['rubygem-aws'],
                   File["/etc/init.d/deltacloud-${name}", "/var/log/deltacloud-${name}"]] }
}

define aeolus::deltacloud::disabled() {
  ### Stop the aeolus services
    service { "deltacloud-${name}":
      ensure  => 'stopped',
      enable  => false,
      hasstatus => true}
    file {"/etc/init.d/deltacloud-${name}":
      ensure => absent,
      require => Service["deltacloud-${name}"]}
}

