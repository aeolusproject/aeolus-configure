# Aeolus puppet definitions

import "postgres"
import "apache"
import "rails"
import "selinux"
import "ntp"

import "conductor"
import "deltacloud"
import "iwhd"
import "image-factory"

if $aeolus_enable_security == "true" or $aeolus_enable_security == "1" {
  import "openssl"
  $enable_security = true
} else {
  $enable_security = false
}

if $aeolus_enable_packages == "true" or $aeolus_enable_packages == "1" {
  $enable_packages = true
} else {
  $enable_packages = false
}

# Base aeolus class
class aeolus {
  package{'curl': ensure => 'installed'}

  # Setup repos which to pull aeolus components
  # TODO:  Don't hardcode these repos to RHEL-6
  #  The issue is that $releasever resolves to something like 6Server
  #  so we either need to have a repo per RHEL variant, or we need
  #  to have smarter logic here
  $base_url_release      = $operatingsystem ? { 'fedora' => "fedora-\$releasever",
                                                'redhat' => 'rhel-6' }
  $pulp_base_url_release = $operatingsystem ? { 'fedora' => "fedora-13",
                                                 'redhat' => 'rhel5' }

  yumrepo{"${name}_arch":
            name     => "${name}_arch",
            descr    => "${name}_arch",
            baseurl  => "http://repos.fedorapeople.org/repos/aeolus/packages/${base_url_release}/\$basearch",
            enabled  => 1, gpgcheck => 0}
  yumrepo{"${name}_noarch":
            name     => "${name}_noarch",
            descr    => "${name}_noarch",
            baseurl  => "http://repos.fedorapeople.org/repos/aeolus/packages/${base_url_release}/noarch",
            enabled  => 1, gpgcheck => 0}

}

# Create a new provider in aeolus
define aeolus::provider($type, $port, $login_user="", $login_password=""){
  aeolus::deltacloud{$name: provider_type => $type, port => $port}
  aeolus::conductor::provider{$name:
                                type           => $type,
                                url            => "http://localhost:${port}/api",
                                login_user     => $login_user,
                                login_password => $login_password,
                                require        => Aeolus::Deltacloud[$name] }
}

