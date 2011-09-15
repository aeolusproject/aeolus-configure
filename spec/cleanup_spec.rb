#   Copyright 2011 Red Hat, Inc.
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.

require 'spec_helper'

require 'nokogiri'
require 'open-uri'

ENV['RAILS_ENV'] = 'production'
$: << "#{CONDUCTOR_PATH}/dutils"
require "dutils"

describe "aeolus-cleanup" do
  before(:all) do
    if $test_scripts
      # !!! need to comment out "#Defaults    requiretty" via visudo for this to work remotely
      #     also need to make sure the user this will be running as has passwordless sudo access
      `sudo /usr/sbin/aeolus-cleanup`
      $?.exitstatus.should == 0
    end
  end

  it "should stop all aeolus services" do
   # TODO were not checking AEOLUS_DEPENDENCY_SERVICES here as some of those don't get stopped
   #        (ssh, postgres for example)
   (AEOLUS_SERVICES).each { |srv|
     `/sbin/service #{srv} status`
      $?.exitstatus.should be(3), "service '#{srv}' should be stopped but it is not"
   }
  end

  it "should disable all aeolus services" do
    (AEOLUS_SERVICES).each { |srv|
      output = `/sbin/chkconfig --list #{srv}`
      output.should_not =~ /.*\:on.*/
    }
  end


end
