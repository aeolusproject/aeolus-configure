require 'spec_helper'
require 'net/ssh'

describe "aeolus-configure install" do
  before(:each) do
    @username = "#{ENV['username']}".empty? ? "root" : "#{ENV['username']}"
    @hostname = "#{ENV['hostname']}".empty? ? "localhost" : "#{ENV['hostname']}"
    @password = "#{ENV['password']}".empty? ? nil : "#{ENV['password']}"
  end

  it "should install all aeolus packages" do
    stdout = ""
    Net::SSH.start(@hostname, @username, :password => @password) do |ssh|
      ssh.exec!("rpm -qa | grep aeolus") do |channel, stream, data|
        stdout << data if stream == :stdout
      end
    end
    stdout.include?("aeolus-conductor-doc").should == true
    stdout.include?("aeolus-conductor").should == true
    stdout.include?("aeolus-conductor-daemons").should == true
    stdout.include?("aeolus-configure").should == true
  end

  it "should start all aeolus services" do
    stdout = ""
    Net::SSH.start(@hostname, @username, :password => @password) do |ssh|
      ["aeolus-conductor", "aeolus-conductor", "iwhd", "conductor-dbomatic", "conductor-condor_refreshd", "postgresql"].each do |service|
        ssh.exec!("/etc/init.d/" + service + " status") do |channel, stream, data|
          stdout << data if stream == :stdout
        end
        stdout.include?("is running").should == true
        stdout = ""
      end
    end
  end

  it "should correctly create an aeolus templates bucket" do
    stdout = ""
    Net::SSH.start(@hostname, @username, :password => @password) do |ssh|
      ssh.exec!("/usr/bin/curl -X GET http://localhost:9090") do |channel, stream, data|
        stdout << data if stream == :stdout
      end
    end
    stdout.include?("http://localhost:9090/templates").should == true
  end

  it "should create a site admin for aeolus conductor" do
    stdout = ""
    Net::SSH.start(@hostname, @username, :password => @password) do |ssh|
      ssh.exec!("echo 'RAILS_ENV=\"production\"' > /tmp/check_admin.rb")
      ssh.exec!("echo 'require \"/usr/share/aeolus-conductor/config/environment\"' >> /tmp/check_admin.rb")
      ssh.exec!("echo 'user=User.find(:all, :conditions => {:login => \"admin\"}).first' >> /tmp/check_admin.rb")
      ssh.exec!("echo 'puts \"email=\" + user.email' >> /tmp/check_admin.rb")
      ssh.exec!("echo 'puts \"first_name=\" + user.first_name' >> /tmp/check_admin.rb")
      ssh.exec!("echo 'puts \"last_name=\" + user.last_name' >> /tmp/check_admin.rb")
      ssh.exec!("ruby /tmp/check_admin.rb") do |channel, stream, data|
        stdout << data if stream == :stdout
      end
      stdout.include?("email=dcuser@aeolusproject.org").should == true
      stdout.include?("first_name=aeolus").should == true
      stdout.include?("last_name=user").should == true
      ssh.exec!("rm -f /tmp/check_admin.rb")
    end
  end

end
