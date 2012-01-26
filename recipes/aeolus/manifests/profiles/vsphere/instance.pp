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

define aeolus::profiles::vsphere::instance ($deltacloud_provider,
                                            $username,
                                            $password,
                                            $datastore,
                                            $network_name)
{
    aeolus::conductor::provider { "${name}":
      deltacloud_driver   => "vsphere",
      url                 => "http://localhost:3002/api",
      deltacloud_provider => "$deltacloud_provider",
      require             => Aeolus::Conductor::Login["admin"],
    }
}
