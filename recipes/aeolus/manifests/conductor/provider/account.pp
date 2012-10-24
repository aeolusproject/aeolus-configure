# Create a new provider account via the conductor
define aeolus::conductor::provider::account($provider="", $type="", $username="",$password="", $account_id="",$x509private="", $x509public="", $admin_login=""){
  if $type != "ec2" {
    web_request{ "provider-account-$name":
      post         => "https://localhost/conductor/providers/0/provider_accounts",
      parameters  => { 'provider_account[label]'  => $name,
                       'provider_account[provider]' => $provider,
                       'provider_account[credentials_hash[username]]'   => $username,
                       'provider_account[credentials_hash[password]]'   => $password,
                       'quota[max_running_instances]'   => 'unlimited',
                       'commit' => 'Save' },

      returns     => '200',
      #contains    => "//table/thead/tr/th[text() = 'Properties for $name']",
      follow      => true,
      use_cookies_at => "/tmp/aeolus-${admin_login}",
      unless      => { 'get'             => 'https://localhost/conductor/provider_accounts',
                       'contains'        => "//html/body//a[text() = '$name']" },
      require    => Service['aeolus-conductor']}

  } else {
    web_request{ "provider-account-$name":
      post         => "https://localhost/conductor/provider_accounts",
      parameters  => { 'provider_account[label]'  => $name,
                       'provider_account[provider]' => $provider,
                       'provider_account[credentials_hash[username]]'   => $username,
                       'provider_account[credentials_hash[password]]'   => $password,
                       'provider_account[credentials_hash[account_id]]' => $account_id,
                       'quota[max_running_instances]'   => 'unlimited',
                       'commit' => 'Save' },
      file_parameters  => { 'provider_account[credentials_hash[x509private]]'=> $x509private,
                            'provider_account[credentials_hash[x509public]]' => $x509public  },

      returns     => '201',
      #contains    => "//table/thead/tr/th[text() = 'Properties for $name']",
      follow      => true,
      use_cookies_at => "/tmp/aeolus-${admin_login}",
      unless      => { 'get'             => 'https://localhost/conductor/provider_accounts',
                       'contains'        => "//html/body//a[text() = '$name']" },
      require    => Service['aeolus-conductor']
    }
  }
}
