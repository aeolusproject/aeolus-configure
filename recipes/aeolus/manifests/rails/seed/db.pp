define aeolus::rails::seed::db($cwd="", $rails_env=""){
  exec{"seed_rails_database":
         cwd         => $cwd,
         environment => "RAILS_ENV=${rails_env}",
         user        => 'aeolus',
         command     => "rake db:seed",
         creates     => "/var/lib/aeolus-conductor/${rails_env}.seed"
         }

   file{"/var/lib/aeolus-conductor/${rails_env}.seed":
         ensure  => present,
         recurse => true,
         require => [Exec['seed_rails_database'], File['/var/lib/aeolus-conductor']]
       }
}
