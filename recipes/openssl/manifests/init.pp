class openssl {
  package { "openssl":
    ensure => installed,
    source => $package_provider
  }
}

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

# Create a ssl certificate at the location specified by the name
# (a '.crt' extension will be appended to the filename).
define openssl::certificate($user='root', $group='root'){
  openssl::key{$name:
     user  => $user,
     group => $group 
  }
  exec{"create_${name}_certificate":
    command => "/usr/bin/openssl req -new -key ${name}.key -days 3650 -out ${name}.crt -x509 -subj '/'",
    require => Openssl::Key[$name]
  }
}
