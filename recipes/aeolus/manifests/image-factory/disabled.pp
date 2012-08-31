class aeolus::image-factory::disabled {
  ### Stop the aeolus services
    service { 'imagefactory':
      ensure  => 'stopped',
      hasstatus => true,
      enable  => false}

  if $aeolus_save_data == "false" {
    ### Destroy and cleanup aeolus artifacts
    exec{"remove_aeolus_templates":     command => "rm -rf /templates"}
    exec{"remove_imagefactory_tmp_files":        command => "rm -rf /var/tmp/imagefactory-mock"}
  }
}
