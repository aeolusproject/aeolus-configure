#   Copyright 2011 Red Hat, Inc.
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.

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

import "defaults"
import "profiles/*"

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
  package{'curl':
    ensure => 'installed',
    source => $package_provider
  }
}
