# Some convenience routines for postgres

package { ["postgresql", "postgresql-server"]:
            ensure => "installed", provider => "yum" }

define postgres::initialize(){
  exec{"initialize_postgres":
         command => "/sbin/service postgresql initdb",
         unless => "/usr/bin/test -d /var/lib/pgsql/data/pg_log",
         require => Package["postgresql-server"]}
}

define postgres::start{
  service {"postgresql" :
         ensure  => running,
         enable  => true,
         require => Exec['initialize_postgres']}
  # XXX ugly hack, postgres takes sometime to startup even though reporting as running
  # need to pause for a bit to ensure it is running before we try to access the db
  exec{"postgresql_startup_pause":
              command => "/bin/sleep 2",
              require => Service[postgresql]
  }
}

define postgres::user($password="", $roles=""){
  exec{"create_dcloud_postgres_user":
         unless  => "/usr/bin/test `psql postgres postgres -P tuples_only -c \"select count(*) from pg_user where usename='${name}';\"` = \"1\"",
         command => "/usr/bin/psql postgres postgres -c \
                     \"CREATE USER ${name} WITH PASSWORD '${password}' ${roles}\""}
}

define postgres::user::remove($password="", $roles=""){
  exec{"remove_dcloud_postgres_user":
         onlyif  => "/usr/bin/test `psql postgres postgres -P tuples_only -c \"select count(*) from pg_user where usename='${name}';\"` = \"1\"",
         command => "/usr/bin/psql postgres postgres -c \
                     \"DROP USER ${name}\""}
}
