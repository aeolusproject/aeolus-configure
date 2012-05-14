class aeolus::iwhd::disabled {
  if $aeolus_save_data == "false" {
    exec { 'clean_iwhd':
      command   => '/usr/bin/ruby /usr/share/aeolus-configure/modules/aeolus/clean-iwhd.rb http://localhost:9090',
      before    => Service[iwhd],
      onlyif    => '/usr/bin/curl http://localhost:9090',
      logoutput => true,
    }
  }

  ### Stop the aeolus services
    service { 'mongod':
      ensure  => 'stopped',
      enable  => false,
      require => Service[iwhd]}

    service { 'iwhd':
      ensure  =>  'stopped',
      enable  =>  false,
      hasstatus =>  true}

}
