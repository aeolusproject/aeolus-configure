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
end
