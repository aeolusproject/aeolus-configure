## Creates apache configs with optional drop files
define apache::site ($ensure = 'present', $source = '') {
    $apache_dir          = "/etc/httpd"
    $apache_conf_dir     = "${apache_dir}/conf.d"
    $site                = "${apache_conf_dir}/${name}"
    $dropdir             = "${site}.d"

    $drop_dir_ensure = $ensure ? {
        "absent"    => "absent",
        default     => directory
    }
    file { $dropdir:
        ensure => $drop_dir_ensure,
        notify => Exec["reload-apache"],
    }

    # create the apache configuration with references to the created dropfiles
	$site_file = "${site}.conf"
	file { $site_file:
        ensure  => $ensure,
        content => template($source),
        notify  => Exec["reload-apache"],
        require => [ Service['httpd'], File[$dropdir] ]
	}
}
