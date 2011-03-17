# Aeolus image factory puppet definitions

class aeolus::image-factory inherits aeolus {
    if $enable_packages {
      package { 'rubygem-deltacloud-image-builder-agent':
                  provider => 'yum', ensure => 'installed',
                  require  => [Yumrepo['aeolus_arch', 'aeolus_noarch']]}

      package { 'imagefactory':
                   provider => 'yum', ensure => 'installed',
                   require => [Yumrepo['aeolus_arch', 'aeolus_noarch']]
      }
    }

  ### Configure pulp to fetch from Fedora
    # TODO uncomment when factory/warehouse uses pulp
    #exec{"pulp_fedora_config":
    #      command => "/usr/bin/pulp-admin -u admin -p admin repo create --id=fedora-repo --feed yum:http://download.fedora.redhat.com/pub/fedora/linux/updates/13/x86_64/"
    #}

  ### Start the aeolus services
    file { "/etc/qpidd.conf":
               source => "puppet:///modules/aeolus_recipe/qpidd.conf",
               mode   => 644 }
    service {'qpidd':
               ensure  => 'running',
               enable  => true,
               require => [File['/etc/qpidd.conf'],
                           return_if($enable_packages, Package['aeolus-conductor-daemons'])]}
    file { "/var/tmp/imagefactory-mock":
               ensure => "directory",
               mode   => 755 }
    $requires = [return_if($enable_packages, Package['rubygem-deltacloud-image-builder-agent']),
                 return_if($enable_packages, Package['aeolus-conductor-daemons']),
                 return_if($enable_packages, Package['imagefactory']),
                 File['/var/tmp/imagefactory-mock'],
                 Service[qpidd],
                 Rails::Seed::Db[seed_aeolus_database]]
    service { 'imagefactoryd':
      ensure  => 'running',
      enable  => true,
      require => $requires}
}

class aeolus::image-factory::disabled {
  ### Stop the aeolus services
    service {'qpidd':
               ensure  => 'stopped',
               enable  => false,
               require => Service['imagefactoryd']}

    service { 'imagefactoryd':
      ensure  => 'stopped',
      enable  => false}

  ### Uninstall the deltacloud components
    if $enable_packages {
      package { 'rubygem-deltacloud-image-builder-agent':
                  provider => 'yum', ensure => 'absent',
                  require  => Package['aeolus-conductor']}

    }

  ### Destroy and cleanup aeolus artifacts
    exec{"remove_aeolus_templates":     command => "/bin/rm -rf /templates"}
}

