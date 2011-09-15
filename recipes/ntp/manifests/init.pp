#   Copyright 2011 Red Hat, Inc.
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.

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
