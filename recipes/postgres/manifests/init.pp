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

class postgres {
    package { "postgresql":
        ensure => installed,
        source => $package_provider
    }
}

class postgres::client inherits postgres {
}

class postgres::server inherits postgres {
    package { [ "postgresql-server" ]:
        ensure => installed,
        source => $package_provider
    }

    group { "postgres":
        gid     => 26,
    }

    service { "postgresql":
        ensure          => running,
        enable          => true,
        hasrestart      => true,
        hasstatus       => true,
        require         => [ Package["postgresql-server"], Exec["pginitdb"] ],
    }

    file { "/var/lib/pgsql/data":
        ensure          => directory,
        owner           => "postgres",
        group           => "postgres",
        require         => Package["postgresql-server"],
    }

    exec { "pginitdb":
        command         => "/usr/bin/initdb --pgdata='/var/lib/pgsql/data' -E UTF8",
        user            => "postgres",
        group           => "postgres",
        creates         => "/var/lib/pgsql/data/PG_VERSION",
        require         => Package["postgresql-server"],
        notify          => Service["postgresql"],
    }

}

define postgres::user($ensure='created', $password="", $roles=""){
  case $ensure {
    'created': {
      exec{"create_${name}_postgres_user":
             unless  => "/usr/bin/test `psql postgres postgres -P tuples_only -c \"select count(*) from pg_user where usename='${name}';\"` = \"1\"",
             command => "/usr/bin/psql postgres postgres -c \
                         \"CREATE USER ${name} WITH PASSWORD '${password}' ${roles}\""}}
    'dropped': {
      exec{"drop_${name}_postgres_user":
             onlyif  => "/usr/bin/test `psql postgres postgres -P tuples_only -c \"select count(*) from pg_user where usename='${name}';\"` = \"1\"",
             command => "/usr/bin/psql postgres postgres -c \
                         \"DROP USER ${name}\""}}
  }
}

