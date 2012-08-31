define aeolus::rails::migrate::db($cwd="", $rails_env=""){
  exec{"migrate_rails_database":
         cwd         => $cwd,
         environment => "RAILS_ENV=${rails_env}",
         command     => "rake db:migrate"}
}
