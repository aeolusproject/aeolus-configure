# Some convenience routines for selinux

define selinux::mode(){
  $mode = $name ? {
    'permissive'    => '0',
    'enforcing'     => '1'
  }
  exec{"set_selinux_${name}":
    command  => "/usr/sbin/setenforce ${mode}"
    unless   => "/usr/bin/test 'Disabled' = `/usr/sbin/getenforce`"
  }
}

