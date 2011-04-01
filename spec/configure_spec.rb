require 'spec_helper'

require 'nokogiri'
require 'open-uri'
require 'postgres'

ENV['RAILS_ENV'] = 'production'
$: << "#{CONDUCTOR_PATH}/dutils"
require "dutils"

describe "aeolus-configure" do
  before(:all) do
    if $test_scripts
      # !!! need to comment out "#Defaults    requiretty" via visudo for this to work remotely
      #     also need to make sure the user this will be running as has passwordless sudo access
      `sudo /usr/sbin/aeolus-configure`
      $?.exitstatus.should == 0
    end
  end

  it "should install all aeolus packages" do
    (AEOLUS_PACKAGES + AEOLUS_DEPENDENCY_PACKAGES).each { |pkg|
      `/bin/rpm -q #{pkg}`
      $?.exitstatus.should be(0), "package '#{pkg}' should be installed but it is not"
    }
  end

  it "should start all aeolus services" do
   (AEOLUS_SERVICES + AEOLUS_DEPENDENCY_SERVICES).each { |srv|
     `/sbin/service #{srv} status`
      $?.exitstatus.should be(0), "service '#{srv}' should be running but it is not"
   }
  end

  it "should correctly create an aeolus templates bucket" do
    doc = Nokogiri::HTML(open(IWHD_URI))
    doc.xpath("//html/body/api/link[@rel='bucket' and @href='#{IWHD_URI}templates']").size.should == 1
  end

  it "should properly setup the postgres db and user" do
    PGconn.open('user=aeolus dbname=conductor').should_not raise_error(PGError)
  end

  it "should create a site admin for aeolus conductor" do
    User.find(:first, :conditions => ["login = 'admin' AND " +
                                      "email = 'dcuser@aeolusproject.org' AND " +
                                      "first_name = 'aeolus' AND " +
                                      "last_name = 'user'"]).should_not be_nil
  end

  it "should properly seed the database" do
    # make sure data created in seed.db is present
    BasePermissionObject.find_by_name("general_permission_scope").should_not be_nil
    Quota.find(:first).should_not be_nil
    ProviderType.find_by_name("Amazon EC2").should_not be_nil
    ProviderType.find_by_codename("mock").should_not be_nil
    # TODO verify metadataobjects and roles exist?
  end

  it "should properly setup apache httpd" do
    # TODO when we re-enable security, test https here
    doc = Nokogiri::HTML(open(CONDUCTOR_URI + "/login"))
    node = doc.xpath("//html/head/title").first
    node.content.should =~ /.*Red Hat Cloud Engine.*/
  end

  it "should properly configure ntpd" do
    #This ensures that ntpd is a client to at least one upstream ntp server
    output = `/bin/echo listpeers | /usr/sbin/ntpdc`
    output.should =~ /.*client.*/
  end

  it "should create mock and ec2 providers" do
    pt = ProviderType.find_by_codename('ec2')
    Provider.find(:first, :conditions => ['name = ? AND provider_type_id = ?', 'ec2-us-east-1', pt.id]).should_not be_nil, "provider ec2-us-east-1 should not be nil"
    Provider.find(:first, :conditions => ['name = ? AND provider_type_id = ?', 'ec2-us-west-1', pt.id]).should_not be_nil, "provider ec2-us-west-1 should not be nil"

    pt = ProviderType.find_by_codename('mock')
    Provider.find(:first, :conditions => ['name = ? AND provider_type_id = ?', 'mock', pt.id]).should_not be_nil, "provider mock should not be nil"
  end

  it "should create an initial hardware profile" do
    HardwareProfile.find_by_name('hwp1').should_not be_nil
  end
end

