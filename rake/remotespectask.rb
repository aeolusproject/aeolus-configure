# Define a remote rspec execution task library

require 'rubygems'
require 'rake'
require 'net/ssh'
require 'net/scp'

module Rake

  # Currently simply scp's the spec suite over to the remote
  # host and ssh's in, executing rspec
  class RemoteSpecTask < TaskLib
    # remote hostname which to connect to
    attr_accessor :hostname

    # remote user to use
    attr_accessor :user

    # remote password to use
    attr_accessor :password

    # local spec directory
    attr_accessor :local_spec_path

    # remote spec directory
    attr_accessor :remote_spec_path

    def initialize(hostname = 'localhost', user = 'root')
      init(hostname, user)
      yield self if block_given?
      define
    end

    def init(hostname, user)
      @hostname = hostname
      @user     = user

      @local_spec_path  = File.expand_path("spec/")
      @remote_spec_path = "/tmp/remote_spec/"
    end

    def define
      desc "execute tests against remote host"
      task :remote_spec, [:hostname, :user, :password] do |t,args|
        @hostname = args.hostname unless args.hostname.nil?
        @user     = args.user     unless args.user.nil?
        @password = args.password unless args.password.nil?

        begin
          Net::SCP.start(@hostname, @user, :password => @password) { |s|
           s.upload(@local_spec_path, @remote_spec_path, :recursive => true)
          }
          Net::SSH.start(@hostname, @user,  :password => @password) do |ssh|
            ssh.exec "RUBYLIB=#{@remote_spec_path} spec #{@remote_spec_path}*_spec.rb" do |ch, stream, data|
              # capture stdout / stderr
              if stream == :stderr
                $stderr.print "#{data}"
              else
                $stdout.print data
              end
            end
          end
          Net::SSH.start(@hostname, @user,  :password => @password) do |ssh|
            ssh.exec "rm -rf #{@remote_spec_path}"
          end
        rescue Net::SSH::AuthenticationFailed
          puts "Could not authenticate #{@user} against #{@hostname}"
        end

      end
    end
  end
end
