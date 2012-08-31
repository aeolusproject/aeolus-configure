define aeolus::selinux::mode(){
  $mode = $name ? {
    'permissive'    => '0',
    'enforcing'     => '1'
  }
  exec{"set_selinux_${name}":
    command  => "setenforce ${mode}",
    unless   => "test 'Disabled' = `getenforce`"
  }
}
