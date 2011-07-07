class aeolus::rhevm inherits aeolus  {
  file {"/etc/rhevm.json":
    content => template("aeolus/rhevm.json"),
    mode => 755,
    require => Package['aeolus-conductor-daemons'] }

  file {"/etc/iwhd/conf.js":
    content => template("aeolus/iwhd-conf.js"),
    mode => 755,
    require => Package['aeolus-conductor-daemons'] }

  file {"$rhevm_nfs_mount_point":
    ensure => 'directory'}

  mount {"$rhevm_nfs_mount_point":
    ensure => mounted,
    device => "$rhevm_nfs_server:$rhevm_nfs_export",
    fstype => "nfs",
    options => "rw",
    require => File["$rhevm_nfs_mount_point"]}

  aeolus::conductor::hwp{"rhevm-hwp":
    memory       => "512",
    cpu          => "1",
    storage      => "1",
    architecture => "x86_64",
    require      => Aeolus::Site_admin["admin"] }

  # break up aeolus::provider into its individual steps for two reasons:
  # 1. deltacloudd expects "rhevm", imagefactory expects "rhev-m" passed through by conductor
  # 2. rhevm-hwp must exist before creating provider
  aeolus::deltacloud{"rhevm":
    provider_type => 'rhevm',
    endpoint => "$rhevm_deltacloud_powershell_url",
    port => $rhevm_deltacloud_port}

  aeolus::conductor::provider{"rhevm":
    type           => "rhevm",
    url            => "http://localhost:${rhevm_deltacloud_port}/api",
    require        => [Aeolus::Deltacloud["rhevm"],Aeolus::Conductor::Hwp["rhevm-hwp"]]}

  # TODO:
  # 1. since we have credentials, create provider account
  # 2. create a realm and mappings
}

class aeolus::rhevm::disabled {
  aeolus::deltacloud::disabled{"rhevm": }

  mount {"$rhevm_nfs_mount_point":
    ensure => unmounted,
    device => "$rhevm_nfs_server:$rhevm_nfs_export"}
}
