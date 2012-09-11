# log out of the aeolus conductor
define aeolus::conductor::logout(){
  web_request{ "${name}-conductor-logout":
    get         => 'https://localhost/conductor/logout',
    returns     => '200',
    follow      => true,
    use_cookies_at => "/tmp/aeolus-$name",
    remove_cookies => true
  }
}
