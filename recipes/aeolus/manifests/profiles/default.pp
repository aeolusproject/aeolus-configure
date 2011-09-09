class aeolus::profiles::default {
  include aeolus::deltacloud::ec2

  aeolus::create_bucket{"aeolus":}

  aeolus::conductor::site_admin{"admin":
     email           => 'dcuser@aeolusproject.org',
     password        => "password",
     first_name      => 'aeolus',
     last_name       => 'user'}

  aeolus::conductor::login{"admin": password => "password",
     require  => Aeolus::Conductor::Site_admin['admin']}

  aeolus::conductor::provider{"mock":
      deltacloud_driver  => 'mock',
      url                => 'http://localhost:3002/api',
      require            => Aeolus::Conductor::Login["admin"] }

  aeolus::conductor::provider::account{"mockuser":
      provider           => 'mock',
      type               => 'mock',
      username           => 'mockuser',
      password           => 'mockpassword',
      require        => Aeolus::Conductor::Provider["mock"] }

  aeolus::conductor::provider{"ec2-us-east-1":
      deltacloud_driver         => 'ec2',
      deltacloud_provider       => 'us-east-1',
      url                       => 'http://localhost:3002/api',
      require        => Aeolus::Conductor::Login["admin"] }

  aeolus::conductor::provider{"ec2-us-west-1":
      deltacloud_driver         => 'ec2',
      deltacloud_provider       => 'us-west-1',
      url                       => 'http://localhost:3002/api',
      require        => Aeolus::Conductor::Login["admin"] }

  aeolus::conductor::hwp{"hwp1":
      memory         => "512",
      cpu            => "1",
      storage        => "",
      architecture   => "x86_64",
      require        => Aeolus::Conductor::Login["admin"] }

  aeolus::conductor::hwp{"hwp2":
    memory         => "1",
    cpu            => "",
    storage        => "1",
    architecture   => "x86_64",
    require        => Aeolus::Conductor::Login["admin"] }

  aeolus::conductor::logout{"admin":
    require    => [Aeolus::Conductor::Provider['mock'],
                   Aeolus::Conductor::Provider::Account['mockuser'],
                   Aeolus::Conductor::Provider['ec2-us-east-1'],
                   Aeolus::Conductor::Provider['ec2-us-west-1'],
                   Aeolus::Conductor::Hwp['hwp1', 'hwp2']] }
}
