# Create a new site admin conductor web user
define aeolus::conductor::site_admin($email="", $password="", $first_name="", $last_name=""){
  exec{"create_site_admin_user":
         cwd         => '/usr/share/aeolus-conductor',
         environment => "RAILS_ENV=production",
         command     => "/usr/bin/rake dc:create_user[${name},${password},${email},${first_name},${last_name}]",
         logoutput   => true,
         unless      => "/usr/bin/test `psql conductor aeolus -P tuples_only -c \"select count(*) from users where login = '${name}';\"` = \"1\"",
         require     => Aeolus::Rails::Seed::Db["seed_aeolus_database"]}
  exec{"grant_site_admin_privs":
         cwd         => '/usr/share/aeolus-conductor',
         environment => "RAILS_ENV=production",
         command     => "/usr/bin/rake dc:site_admin[${name}]",
         logoutput   => true,
         unless      => "/usr/bin/test `psql conductor aeolus -P tuples_only -c \"select count(*) FROM roles INNER JOIN permissions ON (roles.id = permissions.role_id) INNER JOIN users ON (permissions.user_id = users.id) where roles.name = 'base.admin' AND users.login = '${name}';\"` = \"1\"",
         require     => Exec[create_site_admin_user]}
}
