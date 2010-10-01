# Deltacloud puppet definitions

define dc::site_admin($cwd="", $rails_env="", $email="", $password="", $first_name="", $last_name=""){
  exec{"create_site_admin_user":
         cwd         => $cwd,
         environment => "RAILS_ENV=${rails_env}",
         command     => "/usr/bin/rake dc:create_user[${name}] email=${email} password=${password} first_name=${first_name} last_name=${last_name}"}
  exec{"grant_site_admin_privs":
         cwd         => $cwd,
         environment => "RAILS_ENV=${rails_env}",
         command     => "/usr/bin/rake dc:site_admin[${name}]",
         require     => Exec[create_site_admin_user]}
}
