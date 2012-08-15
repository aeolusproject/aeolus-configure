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

class aeolus::profiles::common {
  #we will use one random hex string to name the temporary admin user
  $random = secure_random()
  $temp_admin_login = "temporary-administrative-user-${random}"
  #and another random hex string for the temp user's password
  $temp_admin_password = secure_random()

  aeolus::create_bucket{"aeolus":}

  aeolus::conductor::temp_admin{$temp_admin_login :
     password        => $temp_admin_password }

  aeolus::conductor::login{$temp_admin_login : password => $temp_admin_password,
     require  => Aeolus::Conductor::Temp_admin[$temp_admin_login]}

  aeolus::conductor::hwp{"small-x86_64":
      memory         => "512",
      cpu            => "1",
      storage        => "",
      architecture   => "x86_64",
      admin_login    => $temp_admin_login,
      require        => Aeolus::Conductor::Login[$temp_admin_login] }

  aeolus::conductor::logout{$temp_admin_login:}

  aeolus::conductor::destroy_temp_admins{ "after" :
    require => Aeolus::Conductor::Logout[$temp_admin_login]}

  Aeolus::Conductor::Provider <| |> -> Aeolus::Conductor::Logout <| |>
  Aeolus::Conductor::Provider::Account <| |> -> Aeolus::Conductor::Logout <| |>
  Aeolus::Conductor::Hwp <| |> -> Aeolus::Conductor::Logout <| |>
}
