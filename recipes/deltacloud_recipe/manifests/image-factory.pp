# Deltacloud image factory puppet definitions

class deltacloud::image-factory inherits deltacloud {
    if $enable_packages {
      package { 'rubygem-deltacloud-image-builder-agent':
                  provider => 'yum', ensure => 'installed',
                  require  => [Yumrepo['deltacloud_arch', 'deltacloud_noarch']]}
    }


  ### Configure boxgrinder, this should go into the boxgrinder rpms eventually
    file { "/boxgrinder": ensure => "directory"}
    file { "/boxgrinder/appliances":
              ensure => "directory",
              require => File["/boxgrinder"]}
    file { "/boxgrinder/packaged_builders":
              ensure => "directory",
              require => File["/boxgrinder"]}
    file { "/root/.boxgrinder": ensure => "directory"}
    file { "/root/.boxgrinder/plugins":
              ensure => "directory",
              require => File["/root/.boxgrinder"]}
    file { "/root/.boxgrinder/plugins/local":
                source => "puppet:///modules/deltacloud_recipe/root-boxgrinder-plugins-local",
                mode   => 644,
                require => File["/root/.boxgrinder/plugins"]}
    notify { 'boxgrinder_configured':
                message => 'boxgrinder successfully configured',
                require => File['/root/.boxgrinder/plugins/local',
                                '/boxgrinder/packaged_builders',
                                '/boxgrinder/appliances'] }

  ### Configure pulp to fetch from Fedora
    # TODO uncomment when factory/warehouse uses pulp
    #exec{"pulp_fedora_config":
    #      command => "/usr/bin/pulp-admin -u admin -p admin repo create --id=fedora-repo --feed yum:http://download.fedora.redhat.com/pub/fedora/linux/updates/13/x86_64/"
    #}

  ### Start the deltacloud services
    file { "/etc/qpidd.conf":
               source => "puppet:///modules/deltacloud_recipe/qpidd.conf",
               mode   => 644 }
    service {'qpidd':
               ensure  => 'running',
               enable  => true,
               require => [File['/etc/qpidd.conf'],
                           return_if($enable_packages, Package['deltacloud-aggregator-daemons'])]}
    file { "/etc/imagefactory.yml":
               source => "puppet:///modules/deltacloud_recipe/imagefactory.yml",
               mode   => 644 }
    $requires = [return_if($enable_packages, Package['rubygem-deltacloud-image-builder-agent']),
                 return_if($enable_packages, Package['deltacloud-aggregator-daemons']),
                 File['/etc/imagefactory.yml'],
                 Service[qpidd],
                 Rails::Seed::Db[seed_deltacloud_database],
                 Notify['boxgrinder_configured']]
    service { 'imagefactoryd':
      ensure  => 'running',
      enable  => true,
      require => $requires}
    service { 'deltacloud-image_builder_service':
      ensure    => 'running',
      enable    => true,
      hasstatus => true,
      require   => $requires}
}

class deltacloud::image-factory::disabled {
  ### Stop the deltacloud services
    service {'qpidd':
               ensure  => 'stopped',
               enable  => false,
               require => Service['imagefactoryd', 'deltacloud-image_builder_service']}

    service { 'imagefactoryd':
      ensure  => 'stopped',
      enable  => false}

    service { 'deltacloud-image_builder_service':
        ensure  => 'stopped',
        hasstatus => true,
        enable  => false}


  ### Uninstall the deltacloud components
    if $enable_packages {
      package { 'rubygem-deltacloud-image-builder-agent':
                  provider => 'yum', ensure => 'absent',
                  require  => Package['deltacloud-aggregator']}

      # FIXME these lingering dependencies, pulled in for
      # rubygem-deltacloud-image-builder-agent, need to be removed as
      # appliance-tools depend on them and using
      # 'absent' in the context of the 'yum' provider dispatches
      # to 'rpm -e' instead of 'yum erase'
      package { ['rubygem-boxgrinder-build-ec2-platform-plugin',
                 'rubygem-boxgrinder-build-centos-os-plugin',
                 'rubygem-boxgrinder-build-fedora-os-plugin']:
                 provider => "yum", ensure => 'absent',
                 require  => Package['rubygem-deltacloud-image-builder-agent']}
      package { 'rubygem-boxgrinder-build-rhel-os-plugin':
                 provider => "yum", ensure => 'absent',
                 require  => Package['rubygem-boxgrinder-build-centos-os-plugin']}
      package { 'rubygem-boxgrinder-build-rpm-based-os-plugin':
                 provider => "yum", ensure => 'absent',
                 require  => Package['rubygem-boxgrinder-build-rhel-os-plugin',
                                     'rubygem-boxgrinder-build-fedora-os-plugin']}

      package { 'appliance-tools':
                 provider => 'yum', ensure => 'absent',
                 require  => Package['rubygem-boxgrinder-build-rpm-based-os-plugin']}
      package { 'livecd-tools':
                 provider => 'yum', ensure => 'absent',
                 require  => Package['appliance-tools']}
      package { 'python-imgcreate':
                 provider => 'yum', ensure => 'absent',
                 require  => Package['appliance-tools', 'livecd-tools']}
    }


  ### Destroy and cleanup deltacloud artifacts
    exec{"remove_deltacloud_templates": command => "/bin/rm -rf /templates"}
    exec{"remove_boxgrinder_dir":       command => "/bin/rm -rf /boxgrinder"}
}

