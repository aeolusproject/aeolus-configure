class aeolus::vmware inherits aeolus  {
  file {"/etc/vmware.json":
    content => template("aeolus/vmware.json"),
    mode => 755,
    require => Package['aeolus-conductor-daemons'] }

  aeolus::conductor::hwp{"vsphere-hwp":
    memory       => "256",
    cpu          => "",
    storage      => "",
    architecture => "x86_64",
    require      => Aeolus::Site_admin["admin"] }

  aeolus::deltacloud{"vsphere":
    provider_type => 'vsphere',
    endpoint => "$vmware_api_endpoint",
    port => $vmware_deltacloud_port}

  aeolus::conductor::provider{"vsphere":
    type           => "vsphere",
    url            => "http://localhost:${vmware_deltacloud_port}/api",
    require        => [Aeolus::Deltacloud["vsphere"]]}

}

class aeolus::vmware::disabled {
  aeolus::deltacloud::disabled{"vsphere": }

}
