# Some convenience routines for postgres

file {"/var/deltacloud/": ensure => 'directory' }

define postgres::initialize(){
  exec{"initialize_postgres":
         command => "/sbin/service postgresql initdb",
         creates => "/var/deltacloud/initdb",
         require => File["/var/deltacloud"]}
}

define postgres::start{
  service {"postgresql" :
         ensure => running,
         enable => true
  }
  # XXX ugly hack, postgres takes sometime to startup even though reporting as running
  # need to pause for a bit to ensure it is running before we try to access the db
  exec{"postgresql_startup_pause":
              command => "/bin/sleep 5",
              require => Service[postgresql]
  }
}

define postgres::user($password="", $roles=""){
  exec{"create_dcloud_postgres_user":
         command => "/usr/bin/psql postgres postgres -c \
                     \"CREATE USER ${name} WITH PASSWORD '${password}' ${roles}\"",
         creates => "/var/deltacloud/dcloud_postgres_user",
         require => File["/var/deltacloud"]}
}
