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

# Some convenience routines for rails

define rails::create::db($cwd="", $rails_env=""){
  exec{"create_rails_database":
         cwd         => $cwd,
         environment => "RAILS_ENV=${rails_env}",
         logoutput   => true,
         command     => "/usr/bin/rake db:create"}

}

define rails::migrate::db($cwd="", $rails_env=""){
  exec{"migrate_rails_database":
         cwd         => $cwd,
         environment => "RAILS_ENV=${rails_env}",
         logoutput   => on_failure,
         command     => "/usr/bin/rake db:migrate"}
}

define rails::seed::db($cwd="", $rails_env=""){
  exec{"seed_rails_database":
         cwd         => $cwd,
         environment => "RAILS_ENV=${rails_env}",
         command     => "/usr/bin/rake db:seed",
         logoutput   => true,
         creates     => "/var/lib/aeolus-conductor/${rails_env}.seed"
         }

   file{"/var/lib/aeolus-conductor/${rails_env}.seed":
         ensure  => present,
         recurse => true,
         require => [Exec['seed_rails_database'], File['/var/lib/aeolus-conductor']]
       }
}

define rails::drop::db($cwd="", $rails_env=""){
  exec{"drop_rails_database":
         cwd         => $cwd,
         onlyif      => "/usr/bin/test -f ${cwd}/Rakefile",
         environment => "RAILS_ENV=${rails_env}",
         logoutput   => true,
         command     => "/usr/bin/rake db:drop"}
}

