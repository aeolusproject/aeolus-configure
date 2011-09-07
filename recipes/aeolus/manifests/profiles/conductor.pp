class aeolus::profiles::conductor {

  aeolus::conductor::site_admin{"admin":
     email           => 'dcuser@aeolusproject.org',
     password        => "password",
     first_name      => 'aeolus',
     last_name       => 'user'}

  aeolus::conductor::login{"admin": password => "password",
     require  => Aeolus::Conductor::Site_admin['admin']}

  aeolus::conductor::provider{"mock":
                                type           => "mock",
                                url            => "http://localhost:3002/api"}

  aeolus::conductor::provider::account{"mockuser":
      provider           => 'mock',
      type               => 'mock',
      username           => 'mockuser',
      password           => 'mockpassword',
      require            => Aeolus::Provider["mock"] }

  aeolus::conductor::logout{"admin":
    require    => [Aeolus::Provider['mock'],
                   Aeolus::Conductor::Provider::Account['mockuser'],
                   Aeolus::Provider['ec2-us-east-1'],
                   Aeolus::Provider['ec2-us-west-1']] }

}
