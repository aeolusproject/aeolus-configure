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
# aeolus uninstallation recipe
#

# Modules used by the recipe
import "aeolus_recipe/aeolus"

# disable the various aeolus components
include aeolus::conductor::disabled
include aeolus::deltacloud::disabled
include aeolus::iwhd::disabled
include aeolus::image-factory::disabled
