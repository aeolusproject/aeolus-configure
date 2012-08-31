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

# aeolus iwhd puppet definitions

class aeolus::iwhd inherits aeolus {
  ### Install the deltacloud components
  package { 'iwhd':
             ensure => 'installed',
             provider => $package_provider }

  package { 'mongodb-server':
             ensure => 'installed',
             provider => $package_provider }

  ### Start the aeolus services
    file { "/data":    ensure => 'directory' }
    file { "/data/db": ensure => 'directory' }
    file { "/etc/iwhd": ensure => 'directory'}
    file { "/var/lib/iwhd":  ensure => 'directory' }

    file {"/etc/init.d/iwhd":
      content => template("aeolus/iwhd.init"),
      mode => 755,
      require => Package['iwhd'] }

    file {"/etc/iwhd/users.js":
      content => template("aeolus/iwhd-users.js"),
      mode => 600,
      require => Package['iwhd'] }

    service { 'mongod':
      ensure  => 'running',
      enable  => true,
      require => [Package['mongodb-server'], File["/data/db"]]}

    service { 'iwhd':
      ensure  => 'running',
      enable  => true,
      hasstatus => true,
      require => [Service[mongod],
                  File['/var/lib/iwhd',
                       '/etc/init.d/iwhd',
                       '/etc/iwhd/users.js']]}

    # XXX ugly hack but iwhd might take some time to come up
    exec{"iwhd_startup_pause":
                command => "sleep 2",
                unless  => "curl --proxy '' http://localhost:9090",
                require => Service['iwhd']}
}
