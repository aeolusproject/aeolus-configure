# Deltacloud puppet definitions

import "firewall"

import "postgres"
import "rails"
import "selinux"
import "ntp"

import "aggregator"
import "core"
import "iwhd"
import "image-factory"

# Base deltacloud class
class deltacloud {
  # Setup repos which to pull deltacloud components
  yumrepo{"${name}_arch":
            name     => "${name}_arch",
            descr    => "${name}_arch",
            baseurl  => 'http://repos.fedorapeople.org/repos/deltacloud/appliance/fedora-$releasever/$basearch',
            enabled  => 1, gpgcheck => 0}
  yumrepo{"${name}_noarch":
            name     => "${name}_noarch",
            descr    => "${name}_noarch",
            baseurl  => 'http://repos.fedorapeople.org/repos/deltacloud/appliance/fedora-$releasever/noarch',
            enabled  => 1, gpgcheck => 0}
  yumrepo{"${name}_pulp":
            name     => "${name}_pulp",
            descr    => "${name}_pulp",
            baseurl  => 'http://repos.fedorapeople.org/repos/pulp/pulp/fedora-13/$basearch/',
            enabled  => 1, gpgcheck => 0}
}
