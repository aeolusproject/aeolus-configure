#--
#  Copyright (C) 2010 Red Hat Inc.
#
#  This library is free software; you can redistribute it and/or
#  modify it under the terms of the GNU Lesser General Public
#  License as published by the Free Software Foundation; either
#  version 2.1 of the License, or (at your option) any later version.
#
#  This library is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#  Lesser General Public License for more details.
#
#  You should have received a copy of the GNU Lesser General Public
#  License along with this library; if not, write to the Free Software
#  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307  USA
#
# Author: Mohammed Morsi <mmorsi@redhat.com>
#--

#
# deltacloud thincrust appliance
#

# Modules used by the appliance
import "appliance_base"
import "banners"
import "firewall"
#import "console"

# Information about our appliance
$appliance_name = "Deltacloud Appliance"
$appliance_version = "0.0.2"

# Configuration
appliance_base::setup{$appliance_name:}
appliance_base::enable_updates{$appliance_name:}
banners::all{$appliance_name:}
firewall::setup{$appliance_name: status=>"enabled"}

# Install required gems
single_exec{"install_required_gems":
            command => "/usr/bin/gem install authlogic gnuplot scruffy compass builder compass-960-plugin simple-navigation amazon-ec2"
}

# TODO setup a gem repo w/ latest snapshots of image builder, deltacloud core if we need those

# Deltacloud core
single_exec{"install_deltacloud_core":
            command => "/usr/bin/gem install deltacloud-client deltacloud-core"
}

# Image builder / warehouse

# FIXME when image builder and warehouse are pushed to rubygems and/or rpm is available
# install via that means and remove this wget
single_exec{"download_image_builder":
            command => "/usr/bin/wget http://projects.morsi.org/deltacloud/deltacloud-image-builder-agent-0.0.1.gem http://projects.morsi.org/deltacloud/deltacloud-image-builder-console-0.0.1.gem"
}
single_exec{"install_image_builder":
            command => "/usr/bin/gem install deltacloud-image-builder-agent-0.0.1.gem deltacloud-image-builder-console-0.0.1.gem",
            require => Single_exec[download_image_builder]
}
single_exec{"download_image_warehouse":
            command => "/usr/bin/wget http://projects.morsi.org/deltacloud/iwhd -O /usr/sbin/iwhd && chmod +x /usr/sbin/iwhd"
}
file{"/etc/iwhd/":
     ensure => "directory"
}
file{"/etc/iwhd/conf.js":
     source => "puppet:///deltacloud_appliance/iwhd-conf.js",
     require => File["/etc/iwhd"]
}
file{"/etc/init.d/iwhd":
     source => "puppet:///deltacloud_appliance/iwhd.init",
     mode   => 755
}
service {"iwhd" :
       ensure => running,
       enable => true,
       require => [File["/etc/iwhd/conf.js"], File["/etc/init.d/iwhd"]]
}
single_exec{"create-bucket":
       command => "/usr/bin/curl -X PUT http://localhost:9090/my_bucket",
       require => Service[iwhd]
}

# Pulp
# Configure pulp to fetch from Fedora
# FIXME the locale issue has been fixed, but this command is timing out
# indefinetly due to what seems to be a bug in pulp, did not debug extensively
#single_exec{"pulp_fedora_config":
#            command => "/usr/bin/pulp-admin -u admin -p admin repo create --id=fedora-repo --feed yum:http://download.fedora.redhat.com/pub/fedora/linux/updates/13/x86_64/"
#}

# Configure and start condor-dcloud
file {"/var/lib/condor/condor_config.local":
       source => "puppet:///deltacloud_appliance/condor_config.local",
       notify          => Service[condor]
}
service {"condor" :
       ensure => running,
       enable => true
}

# Configure and start postgres
single_exec {"initialize_db":
      command => "/sbin/service postgresql initdb"
}
file {"/var/lib/pgsql/data/pg_hba.conf":
       source => "puppet:///deltacloud_appliance/pg_hba.conf",
       require => Single_exec[initialize_db]
}
service {"postgresql" :
       ensure => running,
       enable => true,
       require => File["/var/lib/pgsql/data/pg_hba.conf"]
}
# XXX ugly hack, postgres takes sometime to startup even though reporting as running
# need to pause for a bit to ensure it is running before we try to access the db
single_exec{"postgresql_startup_pause":
            command => "/bin/sleep 5",
            require => Service[postgresql]
}
single_exec{"create_dcloud_postgres_user":
            command => "/usr/bin/psql postgres postgres -c \"CREATE USER dcloud WITH PASSWORD 'v23zj59an' CREATEDB\"",
            require => Single_exec[postgresql_startup_pause]
}

# Create deltacloud database
single_exec{"create_deltacloud_database":
            cwd     => "/usr/share/deltacloud-aggregator",
            environment     => "RAILS_ENV=production",
            command         => "/usr/bin/rake db:create:all",
            require => [Single_exec[create_dcloud_postgres_user], Single_exec[install_required_gems], Single_exec[install_deltacloud_core]]
}
single_exec{"migrate_deltacloud_database":
            cwd             => "/usr/share/deltacloud-aggregator",
            environment     => "RAILS_ENV=production",
            command => "/usr/bin/rake db:migrate",
            require => Single_exec[create_deltacloud_database]
}

# install init.d control script for deltacloudd
file {"/etc/init.d/deltacloud-core":
      source => "puppet:///deltacloud_appliance/deltacloud-core",
      mode   => 755
}

# XXX hack, until the compass stylesheets are precompiled for the aggregator
# rpm, precompile them here
single_exec{"precompile_compass_stylesheets":
     command => "/usr/bin/compass compile -e production --force --trace \
                --config   /usr/share/deltacloud-aggregator/config/compass.rb   \
                --sass-dir /usr/share/deltacloud-aggregator/app/stylesheets/ \
                --css-dir  /usr/share/deltacloud-aggregator/public/stylesheets/compiled",
     require => Single_exec[install_required_gems]
}

# Startup Deltacloud services
service {"deltacloud-aggregator" :
       ensure => running,
       enable => true,
       require => [Single_exec[install_required_gems], Single_exec[migrate_deltacloud_database]]
}
service{"deltacloud-core":
       ensure => running,
       enable => true,
       require => [Single_exec[install_deltacloud_core], File["/etc/init.d/deltacloud-core"]]
}

# Create dcuser, setup account
single_exec{"create_dcuser":
            command => "/usr/sbin/useradd dcuser -p ''"
}
file{"/etc/gdm/custom.conf":
     source => "puppet:///deltacloud_appliance/gdm-custom.conf",
     mode   => 755,
     require => Single_exec[create_dcuser]
}
file{["/home/dcuser/.config/", "/home/dcuser/.config/autostart/",
      "/home/dcuser/Desktop"]:
       ensure => "directory",
       require => Single_exec[create_dcuser]
}
file{"/home/dcuser/.config/autostart/deltacloud.desktop":
     source => "puppet:///deltacloud_appliance/deltacloud.desktop",
     mode   => 755,
     require => File["/home/dcuser/.config/autostart"]
}
file{"/home/dcuser/Desktop/deltacloud.desktop":
     source => "puppet:///deltacloud_appliance/deltacloud.desktop",
     mode   => 755,
     require => File["/home/dcuser/Desktop"]
}
file{"/home/dcuser/background.png":
     source => "puppet:///deltacloud_appliance/background.png",
     mode   => 755,
     require => Single_exec[create_dcuser]
}
single_exec{"set_dcuser_background":
            command => "/usr/bin/gconftool-2 --type string --set /desktop/gnome/background/picture_filename '/home/dcuser/background.png'",
            user    => 'dcuser',
            require => [Single_exec[create_dcuser], File["/home/dcuser/background.png"]]
}

#TODO:  Fix me, find a better way to do this...
#Issues:
#  - There isn't a yum repo, just a single file so we can't add repo and use normal package syntac
#  - specifying source to package doesn't seem to make yum do a localinstall instead
#  - package isn't signed (not fixable by us, but makes me sad)

single_exec{"ec2-ami-tools":
	command => "/usr/bin/yum localinstall http://s3.amazonaws.com/ec2-downloads/ec2-ami-tools.noarach.rpm -y --nogpg",
	user => 'root'
}
