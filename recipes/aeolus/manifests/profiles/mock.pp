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

class aeolus::profiles::mock {

  aeolus::create_bucket{"aeolus":}

  aeolus::conductor::site_admin{"admin":
     email           => 'dcuser@aeolusproject.org',
     password        => "password",
     first_name      => 'aeolus',
     last_name       => 'user'}

  aeolus::conductor::login{"admin": password => "password",
     require  => Aeolus::Conductor::Site_admin['admin']}

  aeolus::conductor::provider{"mock":
      deltacloud_driver  => 'mock',
      url                => 'http://localhost:3002/api',
      require            => Aeolus::Conductor::Login["admin"] }

  aeolus::conductor::provider::account{"mockuser":
      provider           => 'mock',
      type               => 'mock',
      username           => 'mockuser',
      password           => 'mockpassword',
      require        => Aeolus::Conductor::Provider["mock"] }

  aeolus::conductor::hwp{"hwp1":
      memory         => "512",
      cpu            => "1",
      storage        => "",
      architecture   => "x86_64",
      require        => Aeolus::Conductor::Login["admin"] }

  aeolus::conductor::logout{"admin":
    require    => [Aeolus::Conductor::Provider['mock'],
                   Aeolus::Conductor::Provider::Account['mockuser'],
                   Aeolus::Conductor::Hwp['hwp1']] }
}
