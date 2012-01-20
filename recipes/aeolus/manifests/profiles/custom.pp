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

class aeolus::profiles::custom {

aeolus::conductor::site_admin{"admin":
   email           => 'dcuser@aeolusproject.org',
   password        => "password",
   first_name      => 'aeolus',
   last_name       => 'user'}

aeolus::conductor::login{"admin": password => "password",
   require  => Aeolus::Conductor::Site_admin['admin']}

#AEOLUS_SEED_DATA

aeolus::conductor::hwp{"hwp1":
    memory         => "1",
    cpu            => "1",
    storage        => "1",
    architecture   => "x86_64",
    require        => Aeolus::Conductor::Login["admin"] }

aeolus::conductor::hwp{"hwp2":
    memory         => "1",
    cpu            => "",
    storage        => "1",
    architecture   => "x86_64",
    require        => Aeolus::Conductor::Login["admin"] }

aeolus::conductor::logout{"admin":
  require    => [#AEOLUS_SEED_DATA_REQUIRES
                 Aeolus::Conductor::Hwp["hwp1", "hwp2"]] }
}
