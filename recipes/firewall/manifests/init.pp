import "defines.pp"

class firewall {

    $firewall_dir = "/usr/share/firewall"
    package { "iptables":
        ensure  => installed,
    }

    service { "firewall":
        name            => "iptables",
        enable          => true,
        hasstatus       => true,
        require         => [ Package["iptables"], File["iptables-update"] ],
        restart         => "/usr/local/bin/iptables-update.sh",
    }

    # the reload script (thanks rmonk)
    file { "iptables-update":
        name    => "/usr/local/bin/iptables-update.sh",
        mode    => 0755,
        source  => "puppet:///modules/firewall/iptables-update.sh",
    }

    file { "${firewall_dir}":
      ensure  => directory,
      mode    => 0755,
    }

    # create the table directories
    file { 
    [
        "${firewall_dir}/filter",
        "${firewall_dir}/filter/INPUT",
        "${firewall_dir}/filter/OUTPUT",
        "${firewall_dir}/filter/FORWARD",
        "${firewall_dir}/nat",
        "${firewall_dir}/nat/PREROUTING",
        "${firewall_dir}/nat/OUTPUT",
        "${firewall_dir}/nat/POSTROUTING",
        "${firewall_dir}/mangle",
        "${firewall_dir}/mangle/FORWARD",
        "${firewall_dir}/mangle/POSTROUTING",
        "${firewall_dir}/mangle/INPUT",
        "${firewall_dir}/raw",
        "${firewall_dir}/raw/PREROUTING",
        "${firewall_dir}/raw/OUTPUT"
    ]:
        ensure          => directory,
        notify          => Service["firewall"],
        require         => File["${firewall_dir}"],
	      mode		        => 0755,
    }

    # create the head/tail  files -- we tried a recursive resource here but it failed.
    $wrapper_rules = [
      'filter/INPUT',
      'filter/OUTPUT',
      'filter/FORWARD',
      'nat/PREROUTING',
      'nat/POSTROUTING',
      'nat/OUTPUT',
      'mangle/FORWARD',
      'mangle/INPUT',
      'mangle/POSTROUTING',
      'raw/PREROUTING',
      'raw/OUTPUT'
    ]

    firewall::rule::stub { $wrapper_rules:
      notify    => Service["firewall"],
      require   => File["${firewall_dir}"],
    }

    # relevent execs
    exec { "reload-firewall":
        command         => "/usr/local/bin/iptables-update.sh",
        require         => File["iptables-update"],
        refreshonly     => true,
    }
}

class firewall::disabled inherits firewall {
    Service["firewall"] {
        ensure  => stopped,
        enable  => false,
    }
}

class firewall::ckmtest inherits firewall {

    firewall::rule { "NAT":
        table               => 'nat',
        chain               => 'PREROUTING',
        protocol            => 'tcp',
        destination_port    => '8443',
        action              => 'REDIRECT',
        to_ports            => "443",
        comment             => "nat rule",
    }
}

