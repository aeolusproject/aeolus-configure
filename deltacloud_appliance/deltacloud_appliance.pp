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
import "deltacloud_appliance"
import "banners"
import "firewall"

# Information about our appliance
$appliance_name = "Deltacloud Appliance"
$appliance_version = "0.0.2"

# Configuration
appliance_base::setup{$appliance_name:}
appliance_base::enable_updates{$appliance_name:}
banners::all{$appliance_name:}
firewall::setup{$appliance_name: status=>"enabled"}

firewall_open_port{"httpd": port => "80", policy => "tcp"}

# TODO put most of this recipe into the deltacloud manifest, replace with:
#
# deltacloud::package{["dependencies", "core", "client",
#                      "factory-agent", "factory-console", "iwhd"]:
#                       ensure => 'installed' }
# deltacloud::db{"postgres":}
# deltacloud::service{["condor", "condor_refreshd",
#                      "httpd", "iwhd",
#                      "core", "dbomatic", "aggregator"]:
#                      ensure => 'running',
#                      require => Deltacloud::Db[postgres]}
# deltacloud::create_bucket{"deltacloud": require => Deltacloud::Service[iwhd]}
# deltacloud::create_users{"dcloud":}
#

# Install gems for deltacloud dependencies and deltacloud core
$deltacloud_deps=["authlogic", "gnuplot", "scruffy", "compass",
                  "compass-960-plugin", "simple-navigation", "amazon-ec2",
                  "typhoeus", "rb-inotify", "right_aws",
                  "deltacloud-client", "deltacloud-core"]
package{$deltacloud_deps:
            provider => 'gem',
            ensure   => 'installed' , require => Single_exec[builder] }

# XXX hack, builder is failing to install via 'package' above, since it outputs
# the text 'ERROR' when installing (yet still succeeds to install).
# /usr/lib/ruby/site_ruby/1.8/puppet/provider/package/gem.rb:104 checks this and
# will report the package as failing to have installed. Temporary workaround until
# this is resolved
single_exec{"builder": command => "/usr/bin/gem install builder"}

# Image builder / warehouse

# FIXME when image builder and warehouse are pushed to rubygems
# and/or rpm is available install via that means and remove this download
standalone_gem { "deltacloud-image-builder-agent-0.0.1.gem":
                    source => "http://projects.morsi.org/deltacloud/deltacloud-image-builder-agent-0.0.1.gem",
                    ensure => installed;
                 "deltacloud-image-builder-console-0.0.1.gem":
                    source => "http://projects.morsi.org/deltacloud/deltacloud-image-builder-console-0.0.1.gem",
                    ensure => installed }

download { "iwhd":
             source => "http://projects.morsi.org/deltacloud/iwhd",
             cwd    => '/usr/sbin/',
             mode   => 755 }

file_with_dir { "conf.js":
                     dir    => "/etc/iwhd",
                     source => "puppet:///deltacloud_appliance/iwhd-conf.js",
                     mode   => 644}

file { "/etc/init.d/iwhd":
         source => "puppet:///deltacloud_appliance/iwhd.init",
         mode   => 755 }

service { "iwhd":
            ensure => running,
            enable => true,
            require => [Download[iwhd], File["/etc/iwhd/conf.js"], File["/etc/init.d/iwhd"]] }

single_exec{"create-bucket":
       command => "/usr/bin/curl -X PUT http://localhost:9090/deltacloud",
       require => Service[iwhd]
}

file { "/boxgrinder": ensure => "directory"}
file { "/boxgrinder/appliances":
          ensure => "directory",
          require => File["/boxgrinder"]}
file { "/boxgrinder/packaged_builders":
          ensure => "directory",
          require => File["/boxgrinder"]}
file { "/root/.boxgrinder": ensure => "directory"}
file { "/root/.boxgrinder/plugins":
          ensure => "directory",
          require => File["/root/.boxgrinder"]}
file { "/root/.boxgrinder/plugins/local":
            source => "puppet:///deltacloud_appliance/root-boxgrinder-plugins-local",
            mode   => 644 }

file { "/etc/qpidd.conf":
            source => "puppet:///deltacloud_appliance/qpidd.conf",
            mode   => 644 }

file { "/etc/imagefactory.yml":
            source => "puppet:///deltacloud_appliance/imagefactory.yml",
            mode   => 644 }

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
file { "/var/lib/pgsql/data/pg_hba.conf":
         source => "puppet:///deltacloud_appliance/pg_hba.conf",
         require => Postgres::Initialize[init_db] }
postgres::initialize{'init_db':}
postgres::start{'start_db': require => File["/var/lib/pgsql/data/pg_hba.conf"]}
postgres::user{"dcloud":
                 password => "v23zj59an",
                 roles    => "CREATEDB",
                 require  => Postgres::Start[start_db]}


# Create deltacloud database
rails::create::db{"create_deltacloud_database":
            cwd        => "/usr/share/deltacloud-aggregator",
            rails_env  => "production",
            require    => [Postgres::User[dcloud], Package[$deltacloud_deps]]}
rails::migrate::db{"migrate_deltacloud_database":
            cwd             => "/usr/share/deltacloud-aggregator",
            rails_env       => "production",
            require         => Rails::Create::Db[create_deltacloud_database]}

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
     require => [Package[compass], Package[compass-960-plugin]]
}

# Startup Deltacloud services
service {"deltacloud-aggregator" :
       ensure => running,
       enable => true,
       require => [Package[$deltacloud_deps], Rails::Migrate::Db[migrate_deltacloud_database], Service[condor]]
}
service {"deltacloud-condor_refreshd" :
       ensure => running,
       enable => true,
       require => [Package[$deltacloud_deps], Rails::Migrate::Db[migrate_deltacloud_database], Service[condor]]
}
service {"deltacloud-dbomatic" :
       ensure => running,
       enable => true,
       require => [Package[$deltacloud_deps], Rails::Migrate::Db[migrate_deltacloud_database], Service[condor]]
}
service{"deltacloud-core":
       ensure => running,
       enable => true,
       require => [Package[$deltacloud_deps], File["/etc/init.d/deltacloud-core"]]
}
service {"httpd" :
       ensure => running,
       enable => true
}

# Create dcuser aggregator web user
dc::site_admin{"dcuser":
     cwd             => "/usr/share/deltacloud-aggregator",
     rails_env       => "production",
     email           => 'dcuser@deltacloud.org',
     password        => 'dcuser',
     first_name      => 'deltacloud',
     last_name       => 'user',
     require         => Rails::Migrate::Db["migrate_deltacloud_database"]}

# Create dcuser system user, setup account
user{"dcuser":
      password => "",
      home     => "/home/dcuser"}
file{"/etc/gdm/custom.conf":
     source => "puppet:///deltacloud_appliance/gdm-custom.conf",
     mode   => 755
}
file{"/home/dcuser":
        ensure  => "directory",
        require => User[dcuser],
        owner   => 'dcuser',
        group   => 'dcuser';
     ["/home/dcuser/.config/",
      "/home/dcuser/Desktop"]:
        ensure  => "directory",
        require => File["/home/dcuser"],
        owner   => 'dcuser',
        group   => 'dcuser';
     "/home/dcuser/.config/autostart/":
        ensure  => "directory",
        require => File["/home/dcuser/.config"],
        owner   => 'dcuser',
        group   => 'dcuser';
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
     require => File["/home/dcuser"]
}
single_exec{"set_dcuser_background":
            command => "/usr/bin/gconftool-2 --type string --set /desktop/gnome/background/picture_filename '/home/dcuser/background.png'",
            user    => 'dcuser',
            require => [File["/home/dcuser"], File["/home/dcuser/background.png"]]
}

#TODO:  Fix me, find a better way to do this...
#Issues:
#  - There isn't a yum repo, just a single file so we can't add repo and use normal package syntac
#  - specifying source to package doesn't seem to make yum do a localinstall instead
#  - package isn't signed (not fixable by us, but makes me sad)

package{"ec2-ami-tools":
        provider => "rpm",
       source => "http://s3.amazonaws.com/ec2-downloads/ec2-ami-tools.noarch.rpm",
       ensure => installed
}
