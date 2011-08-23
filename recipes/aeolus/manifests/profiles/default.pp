class aeolus::profiles::default {

  aeolus::create_bucket{"aeolus":}

  aeolus::conductor::site_admin{"admin":
     email           => 'dcuser@aeolusproject.org',
     password        => "password",
     first_name      => 'aeolus',
     last_name       => 'user'}

  aeolus::conductor::login{"admin": password => "password",
     require  => Aeolus::Conductor::Site_admin['admin']}

  aeolus::provider{"mock":
      type           => 'mock',
      port           => 3002,
      require        => Aeolus::Conductor::Login["admin"] }
  aeolus::conductor::provider::account{"mockuser":
      provider           => 'mock',
      type               => 'mock',
      username           => 'mockuser',
      password           => 'mockpassword',
      require        => Aeolus::Provider["mock"] }

  aeolus::provider{"ec2-us-east-1":
      type           => 'ec2',
      endpoint       => 'us-east-1',
      port           => 3003,
      require        => Aeolus::Conductor::Login["admin"] }

  aeolus::provider{"ec2-us-west-1":
      type           => 'ec2',
      endpoint       => 'us-west-1',
      port           => 3004,
      require        => Aeolus::Conductor::Login["admin"] }

  aeolus::conductor::hwp{"hwp1":
      memory         => "512",
      cpu            => "1",
      storage        => "1",
      architecture   => "x86_64",
      require        => Aeolus::Conductor::Login["admin"] }

  aeolus::conductor::hwp{"hwp2":
    memory         => "1",
    cpu            => "",
    storage        => "1",
    architecture   => "x86_64",
    require        => Aeolus::Conductor::Login["admin"] }

  aeolus::conductor::logout{"admin":
    require    => [Aeolus::Provider['mock'],
                   Aeolus::Conductor::Provider::Account['mockuser'],
                   Aeolus::Provider['ec2-us-east-1'],
                   Aeolus::Provider['ec2-us-west-1'],
                   Aeolus::Conductor::Hwp['hwp1']] }

}
