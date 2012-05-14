define aeolus::rails::create::db($cwd="", $rails_env=""){
  exec{"create_rails_database":
         cwd         => $cwd,
         environment => "RAILS_ENV=${rails_env}",
         logoutput   => true,
         command     => "/usr/bin/rake db:create"}

}
