require 'spec_helper'

require 'nokogiri'
require 'open-uri'

$: << "#{CONDUCTOR_PATH}/dutils"
require "dutils"
 
describe "aeolus-configure install" do
  it "should install all aeolus packages" do
    (AEOLUS_PACKAGES + AEOLUS_DEPENDENCY_PACKAGES).each { |pkg|
      `rpm -q #{pkg}`
      $?.to_i.should be(0), "package '#{pkg}' should be installed but it is not"
    }
  end

  it "should start all aeolus services" do
    (AEOLUS_SERVICES + AEOLUS_DEPENDENCY_SERVICES).each { |srv|
      `service #{srv} status`
       $?.to_i.should be(0), "service '#{srv}' should be running but it is not"
    }
  end

  it "should correctly create an aeolus templates bucket" do
    doc = Nokogiri::HTML(open(IWHD_URI))
    doc.xpath("//html/body/api/link[@rel='bucket' and @href='#{IWHD_URI}templates']").size.should == 1
  end

  it "should create a site admin for aeolus conductor" do
    User.find(:first, :conditions => ["login = 'admin' AND " +
                                      "email = 'dcuser@aeolusproject.org' AND " +
                                      "first_name = 'aeolus' AND " +
                                      "last_name = 'user'"]).should_not be_nil
  end

end
