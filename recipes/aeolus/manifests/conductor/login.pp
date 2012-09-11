# login to the aeolus conductor
define aeolus::conductor::login($password){
  web_request{ "${name}-conductor-login":
    post         => 'https://localhost/conductor/user_session',
    parameters  => { 'username'    => "$name", 'password' => "$password",
                     'commit'                 => 'submit' },
    returns     => '200',
    follow      => true,
    store_cookies_at => "/tmp/aeolus-$name",
    require    => Service['aeolus-conductor']
  }
  exec{"decrement_login_counter":
    cwd         => '/usr/share/aeolus-conductor',
    environment => "RAILS_ENV=production",
    command     => "rake dc:decrement_counter[${name}]",
    require => Web_Request["${name}-conductor-login"]
  }
}
