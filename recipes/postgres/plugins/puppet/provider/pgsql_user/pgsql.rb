require 'puppet/provider/package'

Puppet::Type.type(:pgsql_user).provide(:pgsql,
                                       # T'is funny business, this code is quite generic
                                       :parent => Puppet::Provider::Package) do

  desc "Use pgsql as database."

  # retrieve the current set of pgsql users
  def self.instances
    users = []

    output = execute(['psql', '-Aqtc', "SELECT * FROM pg_authid"], :failonfail => true, :uid => "postgres")
    output.each do |line|
      users << new( query_line_to_hash(line) )
    end
    return users
  end

  def self.query_line_to_hash(line)
    fields = line.chomp.split('|')
    {
      :name       => fields[0],
      :superuser  => fields[1],
      :createrole => fields[3],
      :createdb   => fields[4],
      :password   => fields[8],
      :ensure     => :present
    }
  end

  def query
    result = {}

    output = execute(['psql', '-Aqtc', "SELECT * FROM pg_authid WHERE rolname='#{@resource[:name]}'"], :failonfail => true, :uid => "postgres")
    output.each do |line|
      unless result.empty?
        raise Puppet::Error,
        "Got multiple results for user '%s'" % @resource[:name]
      end
      result = query_line_to_hash(line)
    end
    result
  end
  
  def create
    options = ""
    if @resource.should(:superuser) == :true
      options << " SUPERUSER"
    end
    if @resource.should(:createrole) == :true
      options << " CREATEROLE"
    end
    if @resource.should(:createdb) == :true
      options << " CREATEDB"
    end
      
    execute(['psql', '-Aqtc', "CREATE USER #{@resource[:name]} WITH PASSWORD '#{@resource.should(:password)}' #{options}"], :failonfail => true, :uid => "postgres")
  end

  def destroy
    execute(['dropuser', '-q', "#{@resource[:name]}"], :failonfail => true, :uid => "postgres")
  end

  def exists?
    output = execute(['psql', '-Aqtc', "SELECT rolname FROM pg_authid WHERE rolname='#{@resource[:name]}'"], :failonfail => true, :uid => "postgres")
    output.match(/^#{@resource[:name]}$/)
  end

  def password
    @property_hash[:password]
  end

  def password=(string)
    execute(['psql', '-Aqtc', "ALTER ROLE #{@resource[:name]} WITH ENCRYPTED PASSWORD '#{string}'"], :failonfail => true, :uid => "postgres")
  end

  def superuser
    if @property_hash[:superuser] == "t"
      :true
    else
      :false
    end
  end

  def superuser=(string)
    if string == :true
      execute(['psql', '-Aqtc', "ALTER ROLE #{@resource[:name]} SUPERUSER"], :failonfail => true, :uid => "postgres")
    else
      execute(['psql', '-Aqtc', "ALTER ROLE #{@resource[:name]} NOSUPERUSER"], :failonfail => true, :uid => "postgres")
    end      
  end

  def createrole
    if @property_hash[:createrole] == "t"
      :true
    else
      :false
    end
  end

  def createrole=(string)
    if string == :true
      execute(['psql', '-Aqtc', "ALTER ROLE #{@resource[:name]} CREATEROLE"], :failonfail => true, :uid => "postgres")
    else
      execute(['psql', '-Aqtc', "ALTER ROLE #{@resource[:name]} NOCREATEROLE"], :failonfail => true, :uid => "postgres")
    end      
  end

  def createdb
    if @property_hash[:createdb] == "t"
      :true
    else
      :false
    end
  end

  def createdb=(string)
    if string == :true
      execute(['psql', '-Aqtc', "ALTER ROLE #{@resource[:name]} CREATEDB"], :failonfail => true, :uid => "postgres")
    else
      execute(['psql', '-Aqtc', "ALTER ROLE #{@resource[:name]} NOCREATEDB"], :failonfail => true, :uid => "postgres")
    end      
  end

end
