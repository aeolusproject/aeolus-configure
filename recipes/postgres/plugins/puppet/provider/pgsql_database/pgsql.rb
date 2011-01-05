require 'puppet/provider/package'

Puppet::Type.type(:pgsql_database).provide(:pgsql,
                                           :parent => Puppet::Provider::Package) do

  desc "Use pgsql as database."

  # retrieve the current set of pgsql users
  def self.instances
    dbs = []

    output = execute(['psql', '-Aqtl'], :failonfail => true, :uid => "postgres")
    output.each do |line|
      dbs << new( query_line_to_hash(line) )
    end
    return dbs
  end

  def self.query_line_to_hash(line)
    fields = line.chomp.split('|')
    {
      :name => fields[0],
      :owner => fields[1],
      :ensure => :present
    }
  end

  def query
    result = {
      :name => @resource[:name],
      :owner => @resource[:owner],
      :ensure => :absent
    }
    
    output = execute(['psql', '-Aqtc', "SELECT pg_database.datname, pg_user.usename FROM pg_database, pg_user WHERE pg_database.datname='#{resource[:name]} AND pg_user.usesysid = ( SELECT datdba FROM pg_database WHERE pg_database.datname='#{@resource[:name]}')" ], :failonfail => true, :uid => "postgres")
    output.each do |line|
      result = query_line_to_hash(line)
    end
    result
  end

  def create
    execute(['createdb', '-q', '-O', "#{@resource.should(:owner)}", "#{@resource[:name]}"], :failonfail => true, :uid => "postgres")
  end

  def destroy
    execute(['dropdb', '-q', "#{@resource[:name]}"], :failonfail => true, :uid => "postgres")
  end

  def exists?
    output = execute(['psql', '-Aqtc', "SELECT datname FROM pg_database WHERE datname='#{@resource[:name]}'"], :failonfail => true, :uid => "postgres")
    output.chomp.match(/^#{@resource[:name]}$/)
  end

  def owner
    @property_hash[:owner]
  end

  def owner=(string)
    execute(['psql', '-Aqtc', "UPDATE pg_database SET datdba=(SELECT oid FROM pg_roles WHERE rolname='#{string}') where datname='#{@resource[:name]}'"], :failonfail => true, :uid => "postgres")
  end

end
