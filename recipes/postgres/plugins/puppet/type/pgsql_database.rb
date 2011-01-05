# This has to be a separate type to enable collecting
Puppet::Type.newtype(:pgsql_database) do
  @doc = "Manage a database."
  ensurable
  newparam(:name) do
    desc "The name of the database."
  end
  newproperty(:owner) do
    desc "The owner of the database."

    defaultto "postgres"
  end
end
