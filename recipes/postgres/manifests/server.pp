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
        command         => "/usr/bin/postgresql-setup initdb",
        creates         => "/var/lib/pgsql/data/PG_VERSION",
        require         => Package["postgresql-server"],
        notify          => Service["postgresql"],
    }

}
