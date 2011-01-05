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
