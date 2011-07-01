# Aeolus conductor puppet definitions

class aeolus::conductor inherits aeolus {
  ### Install the aeolus components
    # specific versions of these two packages are needed and we need to pull the third in
    package {['aeolus-conductor',
              'aeolus-conductor-daemons']:
              ensure => 'installed'}

    # to be renamed to aeolus-connector
    package {'rubygem-image_factory_connector':
              ensure => 'installed'}

    file {"/var/lib/aeolus-conductor":
      ensure => directory,
      owner => 'aeolus',
      group => 'aeolus'}

  ### Setup selinux for deltacloud
    selinux::mode{"permissive":}

  ### Start the aeolus services
    file {"/etc/condor/config.d/10deltacloud.config":
           source => "puppet:///modules/aeolus/condor_config.local",
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
      require => File['/etc/condor/config.d/10deltacloud.config'] }
    service { ['aeolus-conductor',
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
               source  => "puppet:///modules/aeolus/pg_hba-ssl.conf",
               require => Exec["pginitdb"],
               owner   => 'postgres',
               group   => 'postgres',
               notify  => Service['postgresql']}
      file { "/var/lib/pgsql/data/postgresql.conf":
               source  => "puppet:///modules/aeolus/postgresql.conf",
               require => Exec["pginitdb"],
               owner   => 'postgres',
               group   => 'postgres',
               notify  => Service['postgresql']}
    } else {
      file { "/var/lib/pgsql/data/pg_hba.conf":
               source => "puppet:///modules/aeolus/pg_hba.conf",
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


  ### Setup/start solr search service
   file{"/etc/init.d/solr":
        source => 'puppet:///modules/aeolus/solr.init',
        mode => 755
   }

   file{"/etc/sysconfig/solr":
        source => 'puppet:///modules/aeolus/solr.conf',
        mode => 755
   }
   # TODO we manually have to install java for solr, we should remove this once this is a dep in the solr rpm
   package{"java-1.6.0-openjdk":
             ensure   => "installed" }
    service{"solr":
             hasstatus   => true,
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
      apache::site{"aeolus-conductor": source => 'puppet:///modules/aeolus/aggregator-httpd-ssl.conf'}
    } else{
      apache::site{"aeolus-conductor": source => 'puppet:///modules/aeolus/aggregator-httpd.conf'}
    }

  ### Setup sshd for deltacloud
	  package { "openssh-server": ensure => installed }
    service{"sshd":
             require  => Package["openssh-server"],
             ensure   =>  'running',
             enable  =>  'true' }
}

class aeolus::conductor::seed_data {
    aeolus::create_bucket{"aeolus":}

    aeolus::site_admin{"$admin_user":
       email           => 'dcuser@aeolusproject.org',
       password        => "$admin_password",
       first_name      => 'aeolus',
       last_name       => 'user'}

    aeolus::provider{"mock":
        type           => 'mock',
        port           => 3002,
        require        => Aeolus::Site_admin["admin"] }

    aeolus::provider{"ec2-us-east-1":
        type           => 'ec2',
        endpoint       => 'us-east-1',
        port           => 3003,
        require        => Aeolus::Site_admin["admin"] }

    aeolus::provider{"ec2-us-west-1":
        type           => 'ec2',
        endpoint       => 'us-west-1',
        port           => 3004,
        require        => Aeolus::Site_admin["admin"] }

    aeolus::conductor::hwp{"hwp1":
        memory         => "1",
        cpu            => "1",
        storage        => "1",
        architecture   => "x86_64",
        require        => Aeolus::Site_admin["admin"] }

}

class aeolus::conductor::remove_seed_data {
    aeolus::deltacloud::disabled{"mock": }
    aeolus::deltacloud::disabled{"ec2-us-east-1": }
    aeolus::deltacloud::disabled{"ec2-us-west-1": }
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
                         'conductor-dbomatic',
                         'conductor-delayed_job'] }
    service { ['aeolus-conductor',
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
                                      "conductor-dbomatic",
                                      "conductor-delayed_job"]}
    postgres::user{"aeolus":
                    ensure => 'dropped',
                    require => Rails::Drop::Db["drop_aeolus_database"]}

  ### stop solr search service
    service{"solr":
                hasstatus => true,
                enable => false,
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

# Create a new provider via the conductor
define aeolus::conductor::provider($type="",$url=""){
  web_request{ "provider-$name":
    post         => "https://localhost/conductor/providers",
    parameters  => { 'provider[name]'  => $name, 'provider[url]'   => $url,
                     'provider[provider_type_codename]' => $type },
    returns     => '200',
    verify      => '.*Provider added.*',
    follow      => true,
    unless      => { 'http_method'     => 'get',
                     'uri'             => 'https://localhost/conductor/providers',
                     'verify'          => ".*$name.*" },
    require    => Service['aeolus-conductor']
  }
}

define aeolus::conductor::hwp($memory='', $cpu='', $storage='', $architecture=''){
  web_request{ "hwp-$name":
    post         => "https://localhost/conductor/hardware_profiles",
    parameters  => {'hardware_profile[name]'  => $name,
                    'hardware_profile[memory_attributes][value]'       => $memory,
                    'hardware_profile[cpu_attributes][value]'          => $cpu,
                    'hardware_profile[storage_attributes][value]'      => $storage,
                    'hardware_profile[architecture_attributes][value]' => $architecture,
                    'hardware_profile[memory_attributes][name]'        => 'memory',
                    'hardware_profile[memory_attributes][unit]'        => 'MB',
                    'hardware_profile[cpu_attributes][name]'           => 'cpu',
                    'hardware_profile[cpu_attributes][unit]'           => 'count',
                    'hardware_profile[storage_attributes][name]'       => 'storage',
                    'hardware_profile[storage_attributes][unit]'       => 'GB',
                    'hardware_profile[architecture_attributes][name]'  => 'architecture',
                    'hardware_profile[architecture_attributes][unit]'  => 'label',
                    'commit' => 'Save'},
    returns     => '200',
    #verify      => '.*Hardware profile added.*',
    follow      => true,
    unless      => { 'http_method'     => 'get',
                     'uri'             => 'https://localhost/conductor/hardware_profiles',
                     'verify'          => ".*$name.*" },
    require    => Service['aeolus-conductor']
  }
}

