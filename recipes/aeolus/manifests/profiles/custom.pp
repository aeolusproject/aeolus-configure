class aeolus::profiles::custom {

aeolus::create_bucket{"aeolus":}

aeolus::conductor::site_admin{"admin":
   email           => 'dcuser@aeolusproject.org',
   password        => "password",
   first_name      => 'aeolus',
   last_name       => 'user'}

aeolus::conductor::login{"admin": password => "password",
   require  => Aeolus::Conductor::Site_admin['admin']}

#AEOLUS_SEED_DATA

aeolus::conductor::hwp{"hwp1":
    memory         => "1",
    cpu            => "1",
    storage        => "1",
    architecture   => "x86_64",
    require        => Aeolus::Conductor::Login["admin"] }

aeolus::conductor::logout{"admin":
  require    => [#AEOLUS_SEED_DATA_REQUIRES
                 Aeolus::Conductor::Hwp["hwp1"]] }
}
