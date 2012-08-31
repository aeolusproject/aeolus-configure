# Create a named bucket in iwhd
define aeolus::create_bucket(){
  exec{"create-bucket-${name}":
         command => "curl --proxy '' -X PUT http://localhost:9090/templates",
         logoutput => true,
         require => [Exec['iwhd_startup_pause'], Package[curl]] }
}
