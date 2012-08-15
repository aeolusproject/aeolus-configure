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

class aeolus::profiles::mock inherits aeolus::profiles::common {
  aeolus::conductor::provider{"mock":
      deltacloud_driver  => 'mock',
      url                => 'http://localhost:3002/api',
      admin_login        => $temp_admin_login,
      require            => Aeolus::Conductor::Login[$temp_admin_login] }


  aeolus::conductor::provider::account{"mock":
      provider           => 'mock',
      type               => 'mock',
      username           => 'mockuser',
      password           => 'mockpassword',
      admin_login        => $temp_admin_login,
      require            => Aeolus::Conductor::Provider["mock"] }
}
