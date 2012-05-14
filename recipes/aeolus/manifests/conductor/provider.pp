# Create a new provider via the conductor
define aeolus::conductor::provider($deltacloud_driver="",$url="", $deltacloud_provider="", $admin_login=""){
  web_request{ "provider-$name":
    post         => "https://localhost/conductor/providers",
    parameters  => { 'provider[name]'  => $name, 'provider[url]'   => $url,
                     'provider[provider_type_deltacloud_driver]' => $deltacloud_driver,
                     'provider[deltacloud_provider]' => $deltacloud_provider },
    returns     => '200',
    follow      => true,
    contains    => "//img[@alt='Notices']", # in the case of an error, @alt='Warnings'
    use_cookies_at => "/tmp/aeolus-${admin_login}",
    log_to      => '/tmp/configure-provider-request.log',
    only_log_errors => true,
    unless      => { 'get'             => 'https://localhost/conductor/providers',
                     'contains'        => "//html/body//a[text() = '$name']" },
    require    => [Service['aeolus-conductor'], Exec['grant_temp_admin_privs'], Exec['deltacloud-core-startup-wait']]
  }
}
