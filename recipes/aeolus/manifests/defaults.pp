#Set up some defaults

$admin_user='admin'
$admin_password='password'

# Setup the default login/logout targets for web requests
Web_request{
  login       => { 'http_method' => 'post',
                   'uri'         =>  'https://localhost/conductor/user_session',
                   'user_session[login]'    => "$admin_user",
                   'user_session[password]' => "$admin_password",
                   'commit'                 => 'submit' },
  logout      => { 'http_method' => 'post',
                   'uri'         =>  'https://localhost/conductor/logout' }
}
