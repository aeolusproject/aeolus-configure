#   Copyright 2012 Red Hat, Inc.
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

define aeolus::profiles::rhevm::instance ( $nfs_server,
                                           $nfs_export,
                                           $nfs_mount_point,
                                           $deltacloud_username,
                                           $deltacloud_password,
                                           $deltacloud_api,
                                           $deltacloud_data_center,
                                           $push_timeout)
{
  aeolus::rhevm::validate{"RHEV NFS export validation for ${name}":
    rhevm_rest_api_url => "$deltacloud_api",
    rhevm_data_center => "$deltacloud_data_center",
    rhevm_username => "$deltacloud_username",
    rhevm_password => "$deltacloud_password",
    rhevm_nfs_export => "$nfs_export"
  }

  file {"$nfs_mount_point":
    ensure => 'directory'}

  mount {"$nfs_mount_point":
    ensure => mounted,
    device => "$nfs_server:$nfs_export",
    fstype => "nfs",
    options => "rw",
    require => [File["$nfs_mount_point"], Aeolus::Rhevm::Validate["RHEV NFS export validation for ${name}"]]}

  aeolus::conductor::provider{"rhevm-${name}":
    deltacloud_driver   => "rhevm",
    url                 => "http://localhost:3002/api",
    deltacloud_provider => "${deltacloud_api};${deltacloud_data_center}",
    admin_login         => $temp_admin_login,
    require             => Aeolus::Conductor::Login[$temp_admin_login] }
}
