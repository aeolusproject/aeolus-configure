$apache_dir          = "/etc/httpd"
$apache_conf_dir     = "${apache_dir}/conf.d"

class apache {
	# require apache and mod_ssl
	package { "httpd": ensure => installed }

  if $enable_security {
	  package { "mod_ssl": ensure => installed }
  }

	service { "httpd":
		ensure     => running,
		require    => Package["httpd"],
		hasrestart => true,
    hasstatus  => true
	}

	exec { "reload-apache":
    command     => "/sbin/service httpd reload",
		refreshonly => true
  }
}

define apache::site ( $ensure = 'present', $source = '') {
	$site_file = "${apache_conf_dir}/${name}.conf"
	file {
		$site_file:
			ensure  => $ensure,
			source  => $source,
			notify  => Exec["reload-apache"],
      require => Service['httpd']
	}
}
