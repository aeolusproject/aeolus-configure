# Create a new site admin conductor web user
class aeolus::conductor::default_admin {
  exec{"create_site_admin_user":
         cwd         => '/usr/share/aeolus-conductor',
         environment => "RAILS_ENV=production",
         command     => "/usr/bin/rake dc:create_user[${admin_login},${admin_password},${admin_email},${admin_first_name},${admin_last_name}]",
         logoutput   => true,
         unless      => "/usr/bin/test `psql conductor aeolus -P tuples_only -c \"select count(*) from roles, permissions, users where roles.id = permissions.role_id and users.id = permissions.user_id and roles.name = 'base.admin' and users.login = '${admin_login}'\"` = \"1\"",
         require     => Rails::Seed::Db["seed_aeolus_database"]}
  exec{"grant_site_admin_privs":
         cwd         => '/usr/share/aeolus-conductor',
         environment => "RAILS_ENV=production",
         command     => "/usr/bin/rake dc:site_admin[${admin_login}]",
         logoutput   => true,
         unless      => "/usr/bin/test `psql conductor aeolus -P tuples_only -c \"select count(*) FROM roles INNER JOIN permissions ON (roles.id = permissions.role_id) INNER JOIN users ON (permissions.user_id = users.id) where roles.name = 'base.admin' AND users.login = '${admin_login}';\"` = \"1\"",
         require     => Exec[create_site_admin_user]}
}
