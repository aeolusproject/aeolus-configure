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

class aeolus::profiles::default {

  aeolus::create_bucket{"aeolus":}

  aeolus::conductor::site_admin{"admin":
     email           => 'root@localhost.localdomain',
     password        => "password",
     first_name      => 'Administrator',
     last_name       => ''}

  aeolus::conductor::login{"admin": password => "password",
     require  => Aeolus::Conductor::Site_admin['admin']}

  aeolus::conductor::hwp{"small-x86_64":
      memory         => "512",
      cpu            => "1",
      storage        => "",
      architecture   => "x86_64",
      require        => Aeolus::Conductor::Login["admin"] }

  aeolus::conductor::logout{"admin":
    require    => Aeolus::Conductor::Hwp['small-x86_64']}

}
