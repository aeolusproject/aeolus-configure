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

# Aeolus deltacloud puppet definitions

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

    # Need to pause for a second for deltacloud-core to complete startup
    # otherwise one may see connect issues when adding providers
    exec{"deltacloud-core-startup-wait":
      cwd         => '/bin',
      command     => "/bin/sleep 1",
      require     => Service["deltacloud-core"]}
}

class aeolus::deltacloud::ec2 {
  ### Install the driver-specific components
   # install ec2 support,
   package { "rubygem-aws":
                ensure => 'installed',
                provider => $package_provider }
}

class aeolus::deltacloud::disabled {
  ### Stop the aeolus services
    service { 'deltacloud-core':
      ensure  => 'stopped',
      enable  => false,
      hasstatus => true}

    # remove deprecated services
    file { '/etc/init.d/deltacloud-ec2-us-east-1': ensure => 'absent' }
    file { '/etc/init.d/deltacloud-ec2-us-west-1': ensure => 'absent' }
    file { '/etc/init.d/deltacloud-mock': ensure => 'absent' }
    file { '/etc/init.d/deltacloud-rhevm': ensure => 'absent' }
    file { '/etc/init.d/deltacloud-vsphere': ensure => 'absent' }
}
