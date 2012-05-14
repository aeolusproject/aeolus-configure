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
