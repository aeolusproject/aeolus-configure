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

class aeolus::profiles::ec2 inherits aeolus::profiles::common {
  include aeolus::deltacloud::ec2

  aeolus::conductor::provider{"ec2-us-east-1":
      deltacloud_driver         => 'ec2',
      deltacloud_provider       => 'us-east-1',
      url                       => 'http://localhost:3002/api',
      admin_login               => $temp_admin_login,
      require        => Aeolus::Conductor::Login[$temp_admin_login] }

  aeolus::conductor::provider{"ec2-us-west-1":
      deltacloud_driver         => 'ec2',
      deltacloud_provider       => 'us-west-1',
      url                       => 'http://localhost:3002/api',
      admin_login               => $temp_admin_login,
      require        => Aeolus::Conductor::Login[$temp_admin_login] }

  aeolus::conductor::provider{"ec2-us-west-2":
      deltacloud_driver         => 'ec2',
      deltacloud_provider       => 'us-west-2',
      url                       => 'http://localhost:3002/api',
      admin_login               => $temp_admin_login,
      require        => Aeolus::Conductor::Login[$temp_admin_login] }

  aeolus::conductor::provider{"ec2-eu-west-1":
      deltacloud_driver         => 'ec2',
      deltacloud_provider       => 'eu-west-1',
      url                       => 'http://localhost:3002/api',
      admin_login               => $temp_admin_login,
      require        => Aeolus::Conductor::Login[$temp_admin_login] }

  aeolus::conductor::provider{"ec2-ap-southeast-1":
      deltacloud_driver		=> 'ec2',
      deltacloud_provider	=> 'ap-southeast-1',
      url			=> 'http://localhost:3002/api',
      admin_login               => $temp_admin_login,
      require        => Aeolus::Conductor::Login[$temp_admin_login] }

  aeolus::conductor::provider{"ec2-ap-northeast-1":
      deltacloud_driver         => 'ec2',
      deltacloud_provider       => 'ap-northeast-1',
      url                       => 'http://localhost:3002/api',
      admin_login               => $temp_admin_login,
      require        => Aeolus::Conductor::Login[$temp_admin_login] }

  aeolus::conductor::provider{"ec2-sa-east-1":
      deltacloud_driver         => 'ec2',
      deltacloud_provider       => 'sa-east-1',
      url                       => 'http://localhost:3002/api',
      admin_login               => $temp_admin_login,
      require        => Aeolus::Conductor::Login[$temp_admin_login] }
}
