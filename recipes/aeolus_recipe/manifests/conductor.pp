# Aeolus conductor puppet definitions

class aeolus::conductor inherits aeolus {
  ### Install the aeolus components
    # specific versions of these two packages are needed and we need to pull the third in
     if $enable_packages {
       package { 'rubygem-deltacloud-client':
                 provider => 'yum', ensure => 'installed', require => Yumrepo['aeolus_arch', 'aeolus_noarch'] }

       package {['aeolus-conductor',
                 'aeolus-conductor-daemons',
                 'aeolus-conductor-doc']:
                 provider => 'yum', ensure => 'installed',
                 require  => Package['rubygem-deltacloud-client',
                                     'rubygem-deltacloud-image-builder-agent',
                                     'iwhd']}
     }

    file {"/var/lib/aeolus-conductor":
            ensure => directory,
    }
  ### Setup selinux for deltacloud
    selinux::mode{"permissive":}

  ### Setup firewall for deltacloud
    firewall::rule{"http":  destination_port => '80' }
    firewall::rule{"https": destination_port => '443'}
    firewall::rule{"ssh":   destination_port => '22'}

  ### Start the aeolus services
    file {"/var/lib/condor/condor_config.local":
           source => "puppet:///modules/aeolus_recipe/condor_config.local",
           require => return_if($enable_packages, Package['aeolus-conductor-daemons']) }
    service { ['condor']:
      ensure  => 'running',
      enable  => true,
      require => File['/var/lib/condor/condor_config.local'] }
    service { ['aeolus-conductor',
               'conductor-condor_refreshd',
               'conductor-dbomatic']:
      ensure    => 'running',
      enable    => true,
      hasstatus => true,
      require => [return_if($enable_packages, Package['aeolus-conductor-daemons']),
                  Rails::Migrate::Db[migrate_aeolus_database],
                  Service['condor', 'httpd']] }

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
                require    => [Postgres::User[aeolus], return_if($enable_packages, Package['aeolus-conductor'])] }
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
           require     => return_if($enable_packages, Package['aeolus-conductor']) }


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
             provider => "yum",
             ensure   => "installed" }
    service{"solr":
             hasstatus   => "false",
             pattern     => "jetty.port=8983",
             ensure      => 'running',
             enable      => 'true',
             require     => [File['/etc/init.d/solr', '/etc/init.d/solr'],
                             Package["java-1.6.0-openjdk"],
                             return_if($enable_packages, Package['aeolus-conductor']),
                             Rails::Create::Db['create_aeolus_database']]}

    exec{"build_solr_index":
                cwd         => "/usr/share/aeolus-conductor",
                command     => "/usr/bin/rake sunspot:reindex",
                logoutput   => true,
                environment => "RAILS_ENV=production",
                require     => Rails::Migrate::Db['migrate_aeolus_database']}

  ### Setup apache for deltacloud
    include apache
    if $enable_security {
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
  ### Uninstall the aeolus components
    if $enable_packages {
      package {['aeolus-conductor-daemons',
                'aeolus-conductor-doc']:
                provider => 'yum', ensure => 'absent',
                require  => Service['aeolus-conductor',
                                    'conductor-condor_refreshd',
                                    'conductor-dbomatic',
                                    'imagefactoryd',
                                    'conductor-image_builder_service']}

      package {'aeolus-conductor':
              provider => 'yum', ensure => 'absent',
              require  => [Package['aeolus-conductor-daemons',
                                   'aeolus-conductor-doc'],
                           Rails::Drop::Db["drop_aeolus_database"],
                           Service['solr']] }

    package { 'rubygem-deltacloud-client':
                provider => 'yum', ensure => 'absent',
                require  => [Package['aeolus-conductor']]}
    }

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
                         'conductor-dbomatic'] }
    service { ['aeolus-conductor',
               'conductor-condor_refreshd',
               'conductor-dbomatic']:
      ensure => 'stopped',
      enable => false,
      hasstatus => true }

  ### Destroy the aeolus database
    rails::drop::db{"drop_aeolus_database":
                cwd        => "/usr/share/aeolus-conductor",
                rails_env  => "production",
                require    => Service["aeolus-conductor",
                                      "conductor-condor_refreshd",
                                      "conductor-dbomatic",
                                      "conductor-image_builder_service"]}
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

