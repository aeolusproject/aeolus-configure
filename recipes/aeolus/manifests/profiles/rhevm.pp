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

class aeolus::profiles::rhevm ($instances) {
  create_resources2('aeolus::profiles::rhevm::instance', $instances)

  file {"/etc/imagefactory/rhevm.json":
    content => template("aeolus/rhevm.json"),
    owner => root,
    group => aeolus,
    mode => 640,
    require => Package['aeolus-conductor-daemons'] }

  aeolus::create_bucket{"aeolus":}

  aeolus::conductor::site_admin{"admin":
     email           => 'dcuser@aeolusproject.org',
     password        => "password",
     first_name      => 'aeolus',
     last_name       => 'user'}

  aeolus::conductor::login{"admin": password => "password",
     require  => Aeolus::Conductor::Site_admin['admin']}

  aeolus::conductor::hwp{"hwp1":
      memory         => "512",
      cpu            => "1",
      storage        => "",
      architecture   => "x86_64",
      require        => Aeolus::Conductor::Login["admin"] }

  aeolus::conductor::logout{"admin":
    require    => Aeolus::Conductor::Hwp['hwp1']}

  Aeolus::Conductor::Provider<| |> -> Aeolus::Conductor::Logout["admin"]
  # TODO: create a realm and mappings
}

define aeolus::rhevm::validate($rhevm_rest_api_url,$rhevm_data_center,$rhevm_username,$rhevm_password,$rhevm_nfs_export){
  $result = rhevm_validate_export_type($rhevm_rest_api_url,$rhevm_data_center,$rhevm_username,$rhevm_password,$rhevm_nfs_export)
  notify {"${name}":
    message => "the RHEV NFS export is on the correct storage domain and has type 'export' => ${result}"
  }
}

class aeolus::profiles::rhevm::disabled {
  exec {"umount $rhevm_nfs_mount_point":
        path => ["/sbin", "/bin"],
        onlyif => [["mount -l | grep $rhevm_nfs_mount_point"],
                   ["/bin/sh -c '! (ps -ef | grep -v grep | grep dc-rhev-image)'"]]}
}
