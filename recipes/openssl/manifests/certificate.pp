# Create a ssl certificate at the location specified by the name
# (a '.crt' extension will be appended to the filename).
define openssl::certificate($user='root', $group='root'){
  openssl::key{$name:
     user  => $user,
     group => $group 
  }
  exec{"create_${name}_certificate":
    command => "openssl req -new -key ${name}.key -days 3650 -out ${name}.crt -x509 -subj '/'",
    require => Openssl::Key[$name]
  }
}
