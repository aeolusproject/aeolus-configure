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
      mode => 755,
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
                command => "/bin/sleep 2",
                unless  => "/usr/bin/curl --proxy '' http://localhost:9090",
                logoutput => true,
                require => Service['iwhd']}
}

class aeolus::iwhd::disabled {
  exec { 'clean_iwhd':
    command => '/usr/bin/ruby /usr/share/aeolus-configure/modules/aeolus/clean-iwhd.rb http://localhost:9090',
    before  => Service[iwhd],
    onlyif  => '/usr/bin/curl http://localhost:9090'
  }

  ### Stop the aeolus services
    service { 'mongod':
      ensure  => 'stopped',
      enable  => false,
      require => Service[iwhd]}

    service { 'iwhd':
      ensure  =>  'stopped',
      enable  =>  false,
      hasstatus =>  true}

   file { "/var/lib/iwhd":
      ensure  => 'absent',
      backup => 'false',
      force   => true,
      require => Service['iwhd']}

}

# Create a named bucket in iwhd
define aeolus::create_bucket(){
  exec{"create-bucket-${name}":
         command => "/usr/bin/curl --proxy '' -X PUT http://localhost:9090/templates",
         logoutput => true,
         require => [Exec['iwhd_startup_pause'], Package[curl]] }
}

