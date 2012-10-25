define aeolus::conductor::temp_admin($password=""){
    exec{"create_temp_admin":
      cwd         => '/usr/share/aeolus-conductor',
      environment => "RAILS_ENV=production",
      user        => 'aeolus',
      command     => "rake dc:create_user[${name},${password},'temp-admin@localhost.localdomain','temp','admin']",
      require     => Rails::Seed::Db["seed_aeolus_database"]}
    exec{"grant_temp_admin_privs":
      cwd         => '/usr/share/aeolus-conductor',
      environment => "RAILS_ENV=production",
      user        => 'aeolus',
      command     => "rake dc:site_admin[${name}]",
      require     => Exec[create_temp_admin]}
}
