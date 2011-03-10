require 'spec_helper'
require 'net/ssh'

def capture_output(command)
  stdout = ""
  IO.popen(command) { |io| stdout << io.read }
  stdout
end

describe "aeolus-configure install" do
  it "should install all aeolus packages" do
    stdout = capture_output("rpm -qa | grep aeolus")
    stdout.include?("aeolus-conductor-doc").should == true
    stdout.include?("aeolus-conductor").should == true
    stdout.include?("aeolus-conductor-daemons").should == true
    stdout.include?("aeolus-configure").should == true
  end

  it "should start all aeolus services" do
   ["aeolus-conductor", "aeolus-conductor", "iwhd", "conductor-dbomatic", "conductor-condor_refreshd", "postgresql"].each do |service|
     stdout = capture_output("/etc/init.d/" + service + " status")
     stdout.include?("is running").should == true
   end
  end

  it "should correctly create an aeolus templates bucket" do
    stdout = capture_output("/usr/bin/curl -X GET http://localhost:9090")
    stdout.include?("http://localhost:9090/templates").should == true
  end

  it "should create a site admin for aeolus conductor" do
      File.open("/tmp/check_admin.rb", "w") { |f|
        f.write("RAILS_ENV='production'\n" +
                "require '/usr/share/aeolus-conductor/config/environment'\n" +
                "user=User.find(:all, :conditions => {:login => 'admin'}).first\n" +
                "puts 'email=' + user.email\n" +
                "puts 'first_name=' + user.first_name\n" +
                "puts 'last_name=' + user.last_name")

      }
      stdout = capture_output("ruby /tmp/check_admin.rb")
      stdout.include?("email=dcuser@aeolusproject.org").should == true
      stdout.include?("first_name=aeolus").should == true
      stdout.include?("last_name=user").should == true
      `rm -f /tmp/check_admin.rb`
  end

end
