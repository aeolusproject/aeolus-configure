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

# Aeolus image factory puppet definitions

class aeolus::image-factory inherits aeolus {

  # image factory client
  package { 'rubygem-aeolus-image': ensure => 'installed' }
  package { 'rubygem-aeolus-cli': ensure => 'installed' }

  # image factory services
  package { 'libvirt':
            ensure=> 'installed',
            provider => $package_provider
  }
  package { 'imagefactory':
               ensure => 'installed',
               provider => $package_provider
  }

  ### Configure pulp to fetch from Fedora
    # TODO uncomment when factory/warehouse uses pulp
    #exec{"pulp_fedora_config":
    #      command => "pulp-admin -u admin -p admin repo create --id=fedora-repo --feed yum:http://download.fedora.redhat.com/pub/fedora/linux/updates/13/x86_64/"
    #}

  ### Start the aeolus services
    file { "/var/tmp/imagefactory-mock":
               ensure => "directory",
               mode   => 755 }
    service {'libvirtd':
               ensure  => 'running',
               enable  => true,
               hasstatus => true,
               require => Package['libvirt']}

    file { "/etc/imagefactory/imagefactory.conf":
      mode => 0600 }

    augeas { 'imagefactory.conf':
      incl => '/etc/imagefactory/imagefactory.conf',
      lens => 'Json.lns',
      changes => ["set /files/etc/imagefactory/imagefactory.conf/dict/entry[. = 'warehouse_key']/string \"$iwhd_oauth_user\"",
                  "set /files/etc/imagefactory/imagefactory.conf/dict/entry[. = 'warehouse_secret']/string \"$iwhd_oauth_password\"",
                  "set /files/etc/imagefactory/imagefactory.conf/dict/entry[. = 'clients']/dict/entry \"$imagefactory_oauth_user\"",
                  "set /files/etc/imagefactory/imagefactory.conf/dict/entry[. = 'clients']/dict/entry/string \"$imagefactory_oauth_password\""],
      require => [Package['imagefactory']]
    }

    $requires = [Package['imagefactory'],
                 File['/var/tmp/imagefactory-mock'],
                 Augeas['imagefactory.conf'],
                 Service[libvirtd]]
    service { 'imagefactory':
      ensure  => 'running',
      enable  => true,
      hasstatus => true,
      require => $requires}
}


