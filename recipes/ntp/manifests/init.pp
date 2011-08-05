class ntp {
    package { "ntp":
        ensure          => installed,
        source => $package_provider
    }
    File {
        owner   => root,
        group   => root,
        mode    => 0644,
    }
}
class ntp::client inherits ntp {
    service { "ntpd":
        ensure          => running,
        enable          => true,
        hasrestart      => true,
        hasstatus       => true,
        require         => Package["ntp"],
    }

    # default ntp servers if none-specified
    # for different environments this should be changed in the branch
    # only setup an override here in case there is an odd host or two
    # that needs to be different from others in the same env
    $default_ntpservers = [ "pool.ntp.org" ]
    $ntpservers = $ntpservers ? {
        ''              => $default_ntpservers,
        default         => $ntpservers,
    }

    file { "/etc/ntp.conf":
        content         => template("ntp/ntp.conf"),
        notify          => Service["ntpd"],
        require         => Package["ntp"],
    }
    file { "/etc/ntp/":
        require         => Package["ntp"],
    }
    file { "/etc/ntp/step-tickers":
        content         => template("ntp/ntp.conf"),
        notify          => Service["ntpd"],
        require         => Package["ntp"],
    }
}
class ntp::server inherits ntp {
}
