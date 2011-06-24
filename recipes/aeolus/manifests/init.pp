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
import "rhevm"
import "vmware"

if $aeolus_enable_https == "true" or $aeolus_enable_https == "1" {
  import "openssl"
  $enable_https = true
} else {
  $enable_https = false
}

if $aeolus_enable_security == "true" or $aeolus_enable_security == "1" {
  import "openssl"
  $enable_security = true
} else {
  $enable_security = false
}


# Base aeolus class
class aeolus {
  package{'curl': ensure => 'installed'}
}

# Create a new provider in aeolus
define aeolus::provider($type, $port, $endpoint=""){
  aeolus::deltacloud{$name: provider_type => $type, endpoint => $endpoint, port => $port}
  aeolus::conductor::provider{$name:
                                type           => $type,
                                url            => "http://localhost:${port}/api",
                                require        => Aeolus::Deltacloud[$name] }
}
