require 'spec_helper'

require 'nokogiri'
require 'open-uri'

ENV['RAILS_ENV'] = 'production'
$: << "#{CONDUCTOR_PATH}/dutils"
require "dutils"

describe "aeolus-cleanup" do
  before(:all) do
    # !!! need to comment out "#Defaults    requiretty" via visudo for this to work remotely
    `sudo /usr/sbin/aeolus-cleanup`
    $?.exitstatus.should == 0
  end

  it "should stop all aeolus services" do
   # TODO were not checking AEOLUS_DEPENDENCY_SERVICES here as some of those don't get stopped
   #        (ssh, postgres for example)
   (AEOLUS_SERVICES).each { |srv|
     `/sbin/service #{srv} status`
      $?.exitstatus.should be(3), "service '#{srv}' should be stopped but it is not"
   }
  end

end
