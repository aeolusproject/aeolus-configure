class ntp::client inherits ntp {
    service { "ntpd":
        ensure          => running,
        enable          => true,
        hasrestart      => true,
        hasstatus       => true,
        require         => Package["ntp"],
    }
}
