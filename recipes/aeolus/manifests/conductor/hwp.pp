define aeolus::conductor::hwp($memory='', $cpu='', $storage='', $architecture='', $admin_login=''){
  web_request{ "hwp-$name":
    post         => "https://localhost/conductor/hardware_profiles",
    parameters  => {'hardware_profile[name]'  => $name,
                    'hardware_profile[memory_attributes][value]'       => $memory,
                    'hardware_profile[cpu_attributes][value]'          => $cpu,
                    'hardware_profile[storage_attributes][value]'      => $storage,
                    'hardware_profile[architecture_attributes][value]' => $architecture,
                    'hardware_profile[memory_attributes][name]'        => 'memory',
                    'hardware_profile[memory_attributes][unit]'        => 'MB',
                    'hardware_profile[cpu_attributes][name]'           => 'cpu',
                    'hardware_profile[cpu_attributes][unit]'           => 'count',
                    'hardware_profile[storage_attributes][name]'       => 'storage',
                    'hardware_profile[storage_attributes][unit]'       => 'GB',
                    'hardware_profile[architecture_attributes][name]'  => 'architecture',
                    'hardware_profile[architecture_attributes][unit]'  => 'label',
                    'commit' => 'Save'},
    returns     => '200',
    #verify      => '.*Hardware profile added.*',
    follow      => true,
    use_cookies_at => "/tmp/aeolus-${admin_login}",
    require    => [Service['aeolus-conductor'], Exec['grant_temp_admin_privs']]
  }
}
