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

class aeolus::profiles::conductor {

  aeolus::conductor::site_admin{"admin":
     email           => 'dcuser@aeolusproject.org',
     password        => "password",
     first_name      => 'aeolus',
     last_name       => 'user'}

  aeolus::conductor::login{"admin": password => "password",
     require  => Aeolus::Conductor::Site_admin['admin']}

  aeolus::conductor::provider{"mock":
                                type           => "mock",
                                url            => "http://localhost:3002/api"}

  aeolus::conductor::provider::account{"mockuser":
      provider           => 'mock',
      type               => 'mock',
      username           => 'mockuser',
      password           => 'mockpassword',
      require            => Aeolus::Provider["mock"] }

  aeolus::conductor::logout{"admin":
    require    => [Aeolus::Provider['mock'],
                   Aeolus::Conductor::Provider::Account['mockuser'],
                   Aeolus::Provider['ec2-us-east-1'],
                   Aeolus::Provider['ec2-us-west-1']] }

}
