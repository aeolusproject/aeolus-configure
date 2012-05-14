# Create a passwordless ssl key at the location specified by the name
# (a '.key' extension will be appended to the filename).
define openssl::key($user='root', $group='root'){
  exec{"create_${name}_key":
    command => "/usr/bin/openssl genrsa -des3 -passout pass:foobar -out ${name}.key 1024"
  }
  exec{"remove_${name}_key_password":
    command => "/usr/bin/openssl rsa -passin pass:foobar -in ${name}.key -out ${name}.key",
    require => Exec["create_${name}_key"]
  }
  exec{"chmod_${name}.key":
    command => "/bin/chmod 400 ${name}.key",
    require => Exec["remove_${name}_key_password"]
  }
  exec{"chown_${name}.key":
    command => "/bin/chown ${user}.${group} ${name}.key",
    require => Exec["chmod_${name}.key"]
  }
}
