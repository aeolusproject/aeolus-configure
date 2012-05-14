define aeolus::rails::drop::db($cwd="", $rails_env=""){
  exec{"drop_rails_database":
         cwd         => $cwd,
         onlyif      => "/usr/bin/test -f ${cwd}/Rakefile",
         environment => "RAILS_ENV=${rails_env}",
         logoutput   => true,
         command     => "/usr/bin/rake db:drop"}
}
