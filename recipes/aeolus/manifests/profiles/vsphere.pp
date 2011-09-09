class aeolus::profiles::vsphere {
  aeolus::create_bucket{"aeolus":}

  aeolus::conductor::site_admin{"admin":
     email           => 'dcuser@aeolusproject.org',
     password        => "password",
     first_name      => 'aeolus',
     last_name       => 'user'}

  aeolus::conductor::login{"admin": password => "password",
     require  => Aeolus::Conductor::Site_admin['admin']}

  aeolus::conductor::provider{"vsphere":
    deltacloud_driver   => "vsphere",
    url                 => "http://localhost:3002/api",
    deltacloud_provider => "$vsphere_deltacloud_provider",
    require             => [Aeolus::Conductor::Login["admin"]] }
    
  aeolus::conductor::provider::account{"vsphere":
      provider           => 'vsphere',
      type               => 'vsphere',
      username           => '$vsphere_username',
      password           => '$vsphere_password',
      require        => Aeolus::Conductor::Provider["vsphere"] }
    
  aeolus::conductor::hwp{"hwp1":
      memory         => "512",
      cpu            => "1",
      storage        => "",
      architecture   => "x86_64",
      require        => Aeolus::Conductor::Login["admin"] }

  aeolus::conductor::logout{"admin":
    require    => [Aeolus::Conductor::Provider['vsphere'],
                   Aeolus::Conductor::Provider::Account['vsphere'],
                   Aeolus::Conductor::Hwp['hwp1']] }
}
