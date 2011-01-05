import "firewall"

class postgres {
    package { "postgresql":
        ensure  => installed,
    }
}

class postgres::client inherits postgres {
}

class postgres::server inherits postgres {
    firewall::rule { "Postgres":
        destination_port    => "5432",
        comment             => "postgresql tcp/5432",
    }

    package { [ "postgresql-server" ]:
        ensure  => installed,
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

    firewall::rule { "POSTGRES-SERVER":
        destination_port        => "5432",
        comment                 => "Postresql inbound 5432/tcp"
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
