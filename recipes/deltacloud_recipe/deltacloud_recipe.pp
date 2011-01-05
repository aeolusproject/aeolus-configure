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
# deltacloud installation recipe
#

# Modules used by the recipe
import "deltacloud_recipe/deltacloud"

# setup the deltacloud repositories
dc::repos{"deltacloud":}

# install deltacloud components
dc::package::install{["aggregator", "core"]:
                        require => Dc::Repos["deltacloud"]}

# setup selinux
dc::selinux{'deltacloud':}

# setup the firewall
dc::firewall{'deltacloud':}

# setup deltacloud db
dc::db{"postgres":}

# start deltacloud services
dc::service::start{["aggregator", "core", 'iwhd', 'image-factory']:}

# create bucket in image warehouse
dc::create_bucket{"deltacloud":}

# Create dcuser aggregator web user
dc::site_admin{"admin":
     email           => 'dcuser@deltacloud.org',
     password        => 'password',
     first_name      => 'deltacloud',
     last_name       => 'user'}
