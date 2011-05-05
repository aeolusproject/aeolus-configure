#Set up some defaults

#Use rpm because it will fail because we don't provide source.
#This is an easy mechanism to have puppet fail when packages
#aren't installed, but also an easy way to tune it back to
#the behavior of installing packages that are missing by
#switching back to yum

Package {provider => 'rpm'}

$admin_user='admin'
$admin_password='password'

# Setup the default login/logout targets for web requests
Web{
  login       => { 'http_method' => 'post',
                   'uri'         =>  'https://localhost/conductor/user_session',
                   'user_session[login]'    => "$admin_user",
                   'user_session[password]' => "$admin_password",
                   'commit'                 => 'submit' },
  logout      => { 'http_method' => 'post',
                   'uri'         =>  'https://localhost/conductor/logout' }
}
