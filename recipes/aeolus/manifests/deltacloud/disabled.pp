class aeolus::deltacloud::disabled {
  ### Stop the aeolus services
    service { 'deltacloud-core':
      ensure  => 'stopped',
      enable  => false,
      hasstatus => true}

    # remove deprecated services
    file { '/etc/init.d/deltacloud-ec2-us-east-1': ensure => 'absent' }
    file { '/etc/init.d/deltacloud-ec2-us-west-1': ensure => 'absent' }
    file { '/etc/init.d/deltacloud-mock': ensure => 'absent' }
    file { '/etc/init.d/deltacloud-rhevm': ensure => 'absent' }
    file { '/etc/init.d/deltacloud-vsphere': ensure => 'absent' }

    if $aeolus_save_data == "false" {
      exec{"remove_deltacloud_tmp_files":        command => "rm -rf /var/tmp/deltacloud-mock*"}
    }
}
