define aeolus::image($template, $provider='', $target='', $hwp=''){
  exec{"build-${name}-image": logoutput => true, timeout => 0,
        command => "/usr/sbin/aeolus-configure-image $name $target $template $provider $hwp",
        require => Service['aeolus-conductor', 'iwhd', 'imagefactory']}

  web_request{ "deployment-$name":
    post        => "https://localhost/conductor/deployments",
    parameters  => { 'deployable_url'  => "http://localhost/deployables/$name.xml",
                     'deployment[name]'    => $name,
                     'deployment[pool_id]' => '1',
                     'deployment[frontend_realm_id]' => '' ,
                     'commit' => 'Next',
                     'suggested_deployable_id' => "other"},
    returns     => '200',
    #contains    => "//html/body//li[text() = 'Provider added.']",
    follow      => true,
    use_cookies_at => '/tmp/aeolus-admin',
    #unless      => { 'get'             => 'https://localhost/conductor/providers',
    #                 'contains'        => "//html/body//a[text() = '$name']" },
    require    => Exec["build-${name}-image"]
  }
}
