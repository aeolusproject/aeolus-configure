# Aeolus conductor puppet definitions

class aeolus::conductor inherits aeolus {
  ### Install the aeolus components
    # specific versions of these two packages are needed and we need to pull the third in
    package {['aeolus-conductor',
              'aeolus-conductor-daemons',
              'aeolus-conductor-doc']:
              ensure => 'installed'}

    # to be renamed to aeolus-connector
    package {'rubygem-image_factory_connector':
              ensure => 'installed'}

    file {"/var/lib/aeolus-conductor":
            ensure => directory }

  ### Setup selinux for deltacloud
    selinux::mode{"permissive":}

  ### Start the aeolus services
    file {"/var/lib/condor/condor_config.local":
           source => "puppet:///modules/aeolus_recipe/condor_config.local",
           require => Package['aeolus-conductor-daemons'] }
     # condor requires an explicit non-localhost hostname
     # TODO we can also kill the configure sequence here instead
     exec{"/bin/echo 'hostname/domain should be explicitly set and should not be localhost.localdomain'":
            logoutput => true,
            onlyif    => "/usr/bin/test `/bin/hostname` = 'localhost.localdomain'"
     }
    service { ['condor']:
      ensure  => 'running',
      enable  => true,
      hasstatus => true,
      require => File['/var/lib/condor/condor_config.local'] }
    service { ['aeolus-conductor',
               'conductor-condor_refreshd',
               'conductor-warehouse_sync',
               'conductor-dbomatic',
               'conductor-delayed_job']:
      ensure    => 'running',
      enable    => true,
      hasstatus => true,
      require => [Package['aeolus-conductor-daemons'],
                  Rails::Migrate::Db[migrate_aeolus_database],
                  Service['condor', 'httpd']] }

    service{ 'aeolus-connector':
      ensure    => 'running',
      enable    => true,
      hasstatus => true,
      require => [Package['rubygem-image_factory_connector'],
		 Service[qpidd]]}

  ### Initialize and start the aeolus database
    # Right now we configure and start postgres, at some point I want
    # to make the db that gets setup configurable
    include postgres::server
    if $enable_security {
      openssl::certificate{"/var/lib/pgsql/data/server":
               user    => 'postgres',
               group   => 'postgres',
               require => Exec["pginitdb"],
               notify  => Service['postgresql']}
      # since we're self signing for now, use the same certificate for the root
      file { "/var/lib/pgsql/data/root.crt":
               require => Openssl::Certificate["/var/lib/pgsql/data/server"],
               source => "/var/lib/pgsql/data/server.crt",
               owner   => 'postgres',
               group   => 'postgres',
               notify  => Service['postgresql'] }
      file { "/var/lib/pgsql/data/pg_hba.conf":
               source  => "puppet:///modules/aeolus_recipe/pg_hba-ssl.conf",
               require => Exec["pginitdb"],
               owner   => 'postgres',
               group   => 'postgres',
               notify  => Service['postgresql']}
      file { "/var/lib/pgsql/data/postgresql.conf":
               source  => "puppet:///modules/aeolus_recipe/postgresql.conf",
               require => Exec["pginitdb"],
               owner   => 'postgres',
               group   => 'postgres',
               notify  => Service['postgresql']}
    } else {
      file { "/var/lib/pgsql/data/pg_hba.conf":
               source => "puppet:///modules/aeolus_recipe/pg_hba.conf",
               require => Exec["pginitdb"],
               notify  => Service['postgresql']}
    }
    postgres::user{"aeolus":
                     password => "v23zj59an",
                     roles    => "CREATEDB",
                     require  => [Service["postgresql"], File["/var/lib/pgsql/data/pg_hba.conf"]] }


    # Create aeolus database
    rails::create::db{"create_aeolus_database":
                cwd        => "/usr/share/aeolus-conductor",
                rails_env  => "production",
                require    => [Postgres::User[aeolus], Package['aeolus-conductor']] }
    rails::migrate::db{"migrate_aeolus_database":
                cwd             => "/usr/share/aeolus-conductor",
                rails_env       => "production",
                require         => [Rails::Create::Db[create_aeolus_database], Service['solr']]}
    rails::seed::db{"seed_aeolus_database":
                cwd             => "/usr/share/aeolus-conductor",
                rails_env       => "production",
                require         => Rails::Migrate::Db[migrate_aeolus_database]}

  ### Prepare the image package repositories
    exec{"dc_prepare_repos":
           cwd         => '/usr/share/aeolus-conductor',
           environment => "RAILS_ENV=production",
           command     => "/usr/bin/rake dc:prepare_repos",
           logoutput   => true,
           require     => Package['aeolus-conductor'] }


  ### Setup/start solr search service
   file{"/etc/init.d/solr":
        source => 'puppet:///modules/aeolus_recipe/solr.init',
        mode => 755
   }

   file{"/etc/sysconfig/solr":
        source => 'puppet:///modules/aeolus_recipe/solr.conf',
        mode => 755
   }
   # TODO we manually have to install java for solr, we should remove this once this is a dep in the solr rpm
   package{"java-1.6.0-openjdk":
             ensure   => "installed" }
    service{"solr":
             hasstatus   => "false",
             pattern     => "jetty.port=8983",
             ensure      => 'running',
             enable      => 'true',
             require     => [File['/etc/init.d/solr', '/etc/init.d/solr'],
                             Package["java-1.6.0-openjdk"],
                             Package['aeolus-conductor'],
                             Rails::Create::Db['create_aeolus_database']]}

    exec{"build_solr_index":
                cwd         => "/usr/share/aeolus-conductor",
                command     => "/usr/bin/rake sunspot:reindex",
                logoutput   => true,
                environment => "RAILS_ENV=production",
                require     => Rails::Migrate::Db['migrate_aeolus_database']}


  ### Setup apache for deltacloud
    include apache
    if $enable_https {
      apache::site{"aeolus-conductor": source => 'puppet:///modules/aeolus_recipe/aggregator-httpd-ssl.conf'}
    } else{
      apache::site{"aeolus-conductor": source => 'puppet:///modules/aeolus_recipe/aggregator-httpd.conf'}
    }

  ### Setup sshd for deltacloud
	  package { "openssh-server": ensure => installed }
    service{"sshd":
             require  => Package["openssh-server"],
             ensure   =>  'running',
             enable  =>  'true' }
}

class aeolus::conductor::disabled {
    file {"/var/lib/aeolus-conductor":
            ensure => absent,
            force  => true
    }

  ### Stop the aeolus services
    service { ['condor', 'httpd']:
      ensure  => 'stopped',
      enable  => false,
      require => Service['aeolus-conductor',
                         'conductor-condor_refreshd',
                         'conductor-warehouse_sync',
                         'conductor-dbomatic',
                         'conductor-delayed_job'] }
    service { ['aeolus-conductor',
               'conductor-condor_refreshd',
               'conductor-warehouse_sync',
               'conductor-dbomatic',
               'conductor-delayed_job',
               'aeolus-connector']:
      ensure => 'stopped',
      enable => false,
      hasstatus => true }

  ### Destroy the aeolus database
    rails::drop::db{"drop_aeolus_database":
                cwd        => "/usr/share/aeolus-conductor",
                rails_env  => "production",
                require    => Service["aeolus-conductor",
                                      "conductor-condor_refreshd",
                                      'conductor-warehouse_sync',
                                      "conductor-dbomatic",
                                      "conductor-delayed_job"]}
    postgres::user{"aeolus":
                    ensure => 'dropped',
                    require => Rails::Drop::Db["drop_aeolus_database"]}

  ### stop solr search service
    service{"solr":
                hasstatus => false,
                stop      => "cd /usr/share/aeolus-conductor;RAILS_ENV=production /usr/bin/rake sunspot:solr:stop",
                pattern   => "solr",
                ensure    => 'stopped',
                require   => Service['aeolus-conductor']}
}

# Create a new site admin conductor web user
define aeolus::site_admin($email="", $password="", $first_name="", $last_name=""){
  exec{"create_site_admin_user":
         cwd         => '/usr/share/aeolus-conductor',
         environment => "RAILS_ENV=production",
         command     => "/usr/bin/rake dc:create_user[${name}] email=${email} password=${password} first_name=${first_name} last_name=${last_name}",
         logoutput   => true,
         unless      => "/usr/bin/test `psql conductor aeolus -P tuples_only -c \"select count(*) from users where login = '${name}';\"` = \"1\"",
         require     => Rails::Seed::Db["seed_aeolus_database"]}
  exec{"grant_site_admin_privs":
         cwd         => '/usr/share/aeolus-conductor',
         environment => "RAILS_ENV=production",
         command     => "/usr/bin/rake dc:site_admin[${name}]",
         logoutput   => true,
         unless      => "/usr/bin/test `psql conductor aeolus -P tuples_only -c \"select count(*) FROM roles INNER JOIN permissions ON (roles.id = permissions.role_id) INNER JOIN users ON (permissions.user_id = users.id) where roles.name = 'Administrator' AND users.login = '${name}';\"` = \"1\"",
         require     => Exec[create_site_admin_user]}
}

define aeolus::conductor::login($user,$password){
  exec{"conductor-login-for-${name}":
         command => "/usr/bin/curl -X POST http://localhost/conductor/user_session \
                      -d user_session[login]=${user} \
                      -d user_session[password]=${password} \
                      -d commit=submit \
                      -c /tmp/aeolus-${user}.cookie \
                      --location --post301 --post302 -k -f",
         onlyif  => "/usr/bin/test ! -f /tmp/aeolus-${user}.cookie || \"\" == \"`curl  -X GET http://localhost/conductor -b /tmp/aeolus-${user}.cookie -i --silent | grep 'HTTP/1.1 200'`\"",
         require => Service['aeolus-conductor', 'httpd']}
}

define aeolus::conductor::logout($user){
  exec{"conductor-logout-for-${name}":
         command => "/usr/bin/curl -X GET http://localhost/conductor/logout -b /tmp/aeolus-${user}.cookie --location -k -f",
         onlyif => "/usr/bin/test -f /tmp/aeolus-${user}.cookie" } # TODO add condition ensuring cookie / session is valid
  exec{"conductor-logout-cookie-for-${name}":
         command   => "/bin/rm /tmp/aeolus-${user}.cookie",
         onlyif    => "/usr/bin/test -f /tmp/aeolus-${user}.cookie",
         require   => Exec["conductor-logout-for-${name}"]}
}


# Create a new provider via the conductor
define aeolus::conductor::provider($type="",$url="",$login_user="",$login_password=""){
  aeolus::conductor::login{"provider-${name}": user => $login_user, password => $login_password }
  exec{"add-conductor-provider-${name}":
         command   => "/usr/bin/curl -X POST http://localhost/conductor/admin/providers \
                         -b /tmp/aeolus-${login_user}.cookie \
                         -d provider[name]=${name} \
                         -d provider[url]=${url} \
                         -d provider[provider_type_codename]=${type} \
                         --location --post301 --post302 -k -f",
         logoutput => true,
         require   => [Aeolus::Conductor::Login["provider-$name"]] }
  aeolus::conductor::logout{"provider-${name}":
         user => $login_user,
         require => Exec["add-conductor-provider-${name}"] }
}

define aeolus::conductor::hwp($memory='', $cpu='', $storage='', $architecture='', $login_user="",$login_password=""){
  aeolus::conductor::login{"hwp-${name}": user => $login_user, password => $login_password }
  exec{"add-conductor-hwp-${name}":
         command   => "/usr/bin/curl -X POST http://localhost/conductor/admin/hardware_profiles \
                         -b /tmp/aeolus-${login_user}.cookie \
                         -d hardware_profile[name]=${name} \
                         -d hardware_profile[memory_attributes][value]=${memory} \
                         -d hardware_profile[cpu_attributes][value]=${cpu} \
                         -d hardware_profile[storage_attributes][value]=${storage} \
                         -d hardware_profile[architecture_attributes][value]=${architecture} \
                         -d hardware_profile[memory_attributes][name]=memory   -d hardware_profile[memory_attributes][unit]=MB \
                         -d hardware_profile[cpu_attributes][name]=cpu         -d hardware_profile[cpu_attributes][unit]=count \
                         -d hardware_profile[storage_attributes][name]=storage -d hardware_profile[storage_attributes][unit]=GB \
                         -d hardware_profile[architecture_attributes][name]=architecture -d hardware_profile[architecture_attributes][unit]=label \
                         -d commit=Save \
                         --location --post301 --post302 -k -f",
         logoutput => true,
         require   => [Aeolus::Conductor::Login["hwp-$name"]] }
  aeolus::conductor::logout{"hwp-${name}":
         user => $login_user,
         require => Exec["add-conductor-hwp-${name}"] }
}

