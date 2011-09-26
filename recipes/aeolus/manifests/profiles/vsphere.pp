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

class aeolus::profiles::vsphere {
  aeolus::create_bucket{"aeolus":}

  file {"/etc/imagefactory/vsphere.json":
    content => template("aeolus/vsphere.json"),
    mode => 755,
    require => Package['aeolus-conductor-daemons'] }

  aeolus::conductor::site_admin{"admin":
     email           => 'dcuser@aeolusproject.org',
     password        => "password",
     first_name      => 'aeolus',
     last_name       => 'user'}

  aeolus::conductor::login{"admin": password => "password",
     require  => Aeolus::Conductor::Site_admin['admin']}

  aeolus::conductor::provider{"vsphere":
    deltacloud_driver   => "vsphere",
    url                 => "http://localhost:3002/api",
    deltacloud_provider => "$vsphere_deltacloud_provider",
    require             => [Aeolus::Conductor::Login["admin"]] }
    
  aeolus::conductor::provider::account{"vsphere":
      provider           => 'vsphere',
      type               => 'vsphere',
      username           => '$vsphere_username',
      password           => '$vsphere_password',
      require        => Aeolus::Conductor::Provider["vsphere"] }
    
  aeolus::conductor::hwp{"hwp1":
      memory         => "512",
      cpu            => "1",
      storage        => "",
      architecture   => "x86_64",
      require        => Aeolus::Conductor::Login["admin"] }

  aeolus::conductor::logout{"admin":
    require    => [Aeolus::Conductor::Provider['vsphere'],
                   Aeolus::Conductor::Provider::Account['vsphere'],
                   Aeolus::Conductor::Hwp['hwp1']] }
}
