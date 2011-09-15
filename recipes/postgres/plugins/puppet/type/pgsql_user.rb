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

# This has to be a separate type to enable collecting

require 'digest/md5'

Puppet::Type.newtype(:pgsql_user) do
  @doc = "Manage a database user."
  ensurable

  newparam(:name) do
    desc "The name of the user"
  end

  newproperty(:password) do
    desc "The unencrypted password of the user."
    munge do |password|
      return 'md5' + Digest::MD5.hexdigest(password + @resource[:name])  
    end
  end

  newproperty(:superuser) do
    desc "Is the user a superuser"

    newvalue(:true)
    newvalue(:false)

    defaultto :false
  end

  newproperty(:createdb) do
    desc "Is the user a allowed to create new databases"

    newvalue(:true)
    newvalue(:false)

    defaultto :false
  end

  newproperty(:createrole) do
    desc "Is the user a allowed to create new roles"

    newvalue(:true)
    newvalue(:false)

    defaultto :false
  end

end
