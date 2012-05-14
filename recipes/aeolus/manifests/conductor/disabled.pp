class aeolus::conductor::disabled {
  if $aeolus_save_data == "false" {
    file {"/var/lib/aeolus-conductor":
            ensure => absent,
            force  => true
    }
  }

    file {"/etc/rsyslog.d/aeolus.conf":
            ensure => absent,
            force  => true
    }

  ### Stop the aeolus services
    service { ['httpd']:
      ensure  => 'stopped',
      enable  => false,
      require => Service['aeolus-conductor',
                         'conductor-dbomatic'] }
    service { ['aeolus-conductor',
               'conductor-dbomatic',
               'conductor-delayed_job']:
      ensure => 'stopped',
      enable => false,
      hasstatus => true }

  if $aeolus_save_data == "false" {
    ### Destroy the aeolus database
    aeolus::rails::drop::db{"drop_aeolus_database":
                cwd        => "/usr/share/aeolus-conductor",
                rails_env  => "production",
                require    => Service["aeolus-conductor",
                                      "conductor-dbomatic",
                                      "conductor-delayed_job"]}
    postgres::user{"aeolus":
                    ensure => 'dropped',
                    require => Aeolus::Rails::Drop::Db["drop_aeolus_database"]}
  }
}
