define aeolus::conductor::destroy_temp_admins {
  exec{"destroy_temp_admin-${name}":
    cwd         => '/usr/share/aeolus-conductor',
    environment => "RAILS_ENV=production",
    user        => 'aeolus',
    command     => "rake dc:destroy_users_by_pattern[temporary-administrative-user-%]",
    require     => Rails::Seed::Db["seed_aeolus_database"]
  }
}
