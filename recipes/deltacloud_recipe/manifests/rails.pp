# Some convenience routines for rails

define rails::create::db($cwd="", $rails_env=""){
  exec{"create_rails_database":
         cwd         => $cwd,
         environment => "RAILS_ENV=${rails_env}",
         command     => "/usr/bin/rake db:create"}

}

define rails::migrate::db($cwd="", $rails_env=""){
  exec{"migrate_rails_database":
         cwd         => $cwd,
         environment => "RAILS_ENV=${rails_env}",
         command     => "/usr/bin/rake db:migrate"}
}

define rails::seed::db($cwd="", $rails_env=""){
  exec{"seed_rails_database":
         cwd         => $cwd,
         environment => "RAILS_ENV=${rails_env}",
         command     => "/usr/bin/rake db:seed",
         creates     => "/var/lib/deltacloud-aggregator/${rails_env}.seed"
         }

   file{"/var/lib/deltacloud-aggregator/${rails_env}.seed":
         ensure  => present,
         recurse => true,
         require => [Exec['seed_rails_database'], File['/var/lib/deltacloud-aggregator']]
       }
}

define rails::drop::db($cwd="", $rails_env=""){
  exec{"drop_rails_database":
         cwd         => $cwd,
         onlyif      => "/usr/bin/test -f ${cwd}/Rakefile",
         environment => "RAILS_ENV=${rails_env}",
         command     => "/usr/bin/rake db:drop"}
}

