# Create a new site admin conductor web user
define aeolus::conductor::site_admin($email="", $password="", $first_name="", $last_name=""){
  exec{"create_site_admin_user":
         cwd         => '/usr/share/aeolus-conductor',
         environment => "RAILS_ENV=production",
         command     => "rake dc:create_user[${name},${password},${email},${first_name},${last_name}]",
         logoutput   => true,
         unless      => 'rake dc:admin_exists',
         require     => Aeolus::Rails::Seed::Db["seed_aeolus_database"]}
  exec{"grant_site_admin_privs":
         cwd         => '/usr/share/aeolus-conductor',
         environment => "RAILS_ENV=production",
         command     => "rake dc:site_admin[${name}]",
         logoutput   => true,
         subscribe   => Exec[create_site_admin_user],
         refreshonly => true}
}
