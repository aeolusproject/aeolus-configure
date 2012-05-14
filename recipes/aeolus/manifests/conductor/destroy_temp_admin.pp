define aeolus::conductor::destroy_temp_admin{
  exec{"destroy_temp_admin":
    cwd         => '/usr/share/aeolus-conductor',
    environment => "RAILS_ENV=production",
    command     => "/usr/bin/rake dc:destroy_user[${name}]",
    logoutput   => true,
    require     => Rails::Seed::Db["seed_aeolus_database"]
  }
}
