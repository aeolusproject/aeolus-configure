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
  file{"/root/.aeolus-cli":
    source => "/usr/lib/ruby/gems/1.8/gems/aeolus-image-0.1.0/examples/aeolus-cli",
    require => Package['rubygem-aeolus-image'] }

  # image factory services
  package { 'libvirt':
            ensure=> 'installed',
            provider => $package_provider
  }
  package { 'imagefactory':
               ensure => 'installed',
               provider => $package_provider
  }
  package { 'qpid-cpp-server':
               ensure => 'installed',
               provider => $package_provider }

  ### Configure pulp to fetch from Fedora
    # TODO uncomment when factory/warehouse uses pulp
    #exec{"pulp_fedora_config":
    #      command => "/usr/bin/pulp-admin -u admin -p admin repo create --id=fedora-repo --feed yum:http://download.fedora.redhat.com/pub/fedora/linux/updates/13/x86_64/"
    #}

  ### Start the aeolus services
    file { "/etc/qpidd.conf":
               source => "puppet:///modules/aeolus/qpidd.conf",
               mode   => 644 }
    service {'qpidd':
               ensure  => 'running',
               enable  => true,
               require => [File['/etc/qpidd.conf'],
                           Package['qpid-cpp-server']]}
    file { "/var/tmp/imagefactory-mock":
               ensure => "directory",
               mode   => 755 }
    service {'libvirtd':
               ensure  => 'running',
               enable  => true,
               hasstatus => true,
               require => Package['libvirt']}
    $requires = [Package['imagefactory'],
                 File['/var/tmp/imagefactory-mock'],
                 Service[qpidd], Service[libvirtd],
                 Rails::Seed::Db[seed_aeolus_database]]
    service { 'imagefactory':
      ensure  => 'running',
      enable  => true,
      hasstatus => true,
      require => $requires}
}

class aeolus::image-factory::disabled {
  ### Stop the aeolus services
    service {'qpidd':
               ensure  => 'stopped',
               enable  => false,
               require => Service['imagefactory']}

    service { 'imagefactory':
      ensure  => 'stopped',
      hasstatus => true,
      enable  => false}

  ### Destroy and cleanup aeolus artifacts
    exec{"remove_aeolus_templates":     command => "/bin/rm -rf /templates"}
}

define aeolus::image($template, $provider='', $target='', $hwp=''){
  exec{"build-$name-image": logoutput => true, timeout => 0,
        command => "/usr/sbin/aeolus-configure-image $name $target $template $provider $hwp",
        require => Service['aeolus-conductor', 'iwhd', 'imagefactory']}

  web_request{ "deployment-$name":
    post        => "https://localhost/conductor/deployments",
    parameters  => { 'deployable_url'  => "http://localhost/deployables/$name.xml",
                     'deployment[name]'    => $name,
                     'deployment[pool_id]' => '1',
                     'deployment[frontend_realm_id]' => '' ,
                     'commit' => 'Next',
                     'suggested_deployable_id' => "other"},
    returns     => '200',
    #contains    => "//html/body//li[text() = 'Provider added.']",
    follow      => true,
    use_cookies_at => '/tmp/aeolus-admin',
    #unless      => { 'get'             => 'https://localhost/conductor/providers',
    #                 'contains'        => "//html/body//a[text() = '$name']" },
    require    => Exec["build-$name-image"]
  }
}
