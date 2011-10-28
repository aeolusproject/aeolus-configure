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

class aeolus::profiles::rhevm {
  file {"/etc/imagefactory/rhevm.json":
    content => template("aeolus/rhevm.json"),
    mode => 755,
    require => Package['aeolus-conductor-daemons'] }

  file {"$rhevm_nfs_mount_point":
    ensure => 'directory'}

  mount {"$rhevm_nfs_mount_point":
    ensure => mounted,
    device => "$rhevm_nfs_server:$rhevm_nfs_export",
    fstype => "nfs",
    options => "rw",
    require => File["$rhevm_nfs_mount_point"]}

  aeolus::create_bucket{"aeolus":}

  aeolus::conductor::site_admin{"admin":
     email           => 'dcuser@aeolusproject.org',
     password        => "password",
     first_name      => 'aeolus',
     last_name       => 'user'}

  aeolus::conductor::login{"admin": password => "password",
     require  => Aeolus::Conductor::Site_admin['admin']}

  aeolus::conductor::provider{"rhevm":
    deltacloud_driver   => "rhevm",
    url                 => "http://localhost:3002/api",
    deltacloud_provider => "$rhevm_deltacloud_provider",
    require             => Aeolus::Conductor::Login["admin"] }

  aeolus::conductor::provider::account{"rhevm":
      provider           => 'rhevm',
      type               => 'rhevm',
      username           => '$rhevm_deltacloud_username',
      password           => '$rhevm_deltacloud_password',
      require        => Aeolus::Conductor::Provider["rhevm"] }

  aeolus::conductor::hwp{"hwp1":
      memory         => "512",
      cpu            => "1",
      storage        => "",
      architecture   => "x86_64",
      require        => Aeolus::Conductor::Login["admin"] }

  aeolus::conductor::logout{"admin":
    require    => [Aeolus::Conductor::Provider['rhevm'],
                   Aeolus::Conductor::Provider::Account['rhevm'],
                   Aeolus::Conductor::Hwp['hwp1']] }

  # TODO: create a realm and mappings
}

class aeolus::profiles::rhevm::disabled {
  mount {"$rhevm_nfs_mount_point":
    ensure => unmounted,
    device => "$rhevm_nfs_server:$rhevm_nfs_export"}
}
