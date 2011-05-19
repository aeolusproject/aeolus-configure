class apache {
	# require apache and mod_ssl
	package { "httpd": ensure => installed }

  if $enable_https {
	  package { "mod_ssl": ensure => installed }
  }

  # if selinux is enabled and we want to use mod_proxy, we need todo this
  exec{'permit-http-networking':
         command => '/usr/sbin/setsebool httpd_can_network_connect 1',
         logoutput => true,
         unless   => "/usr/bin/test 'Disabled' = `/usr/sbin/getenforce`"
  }

	service { "httpd":
		ensure     => running,
		require    => [Package["httpd"], Exec['permit-http-networking']],
		hasrestart => true,
    hasstatus  => true,
    enable     => true
	}

	exec { "reload-apache":
    command     => "/sbin/service httpd reload",
		refreshonly => true
  }
}

define apache::site ( $ensure = 'present', $source = '') {
  $apache_dir          = "/etc/httpd"
  $apache_conf_dir     = "${apache_dir}/conf.d"

	$site_file = "${apache_conf_dir}/${name}.conf"
	file {
		$site_file:
			ensure  => $ensure,
			source  => $source,
			notify  => Exec["reload-apache"],
      require => Service['httpd']
	}
}

