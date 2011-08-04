require 'spec_helper'

require 'fileutils'
require 'curb'

# FIXME should verify agaist ec2 somehow (perhaps using the mock_ec2 driver?)

describe "aeolus-configure seed data api" do
  before(:all) do
    # !!! need to comment out "#Defaults    requiretty" via visudo for this to work remotely
    #     also need to make sure the user this will be running as has passwordless sudo access

    `sudo /usr/sbin/aeolus-cleanup`
    $?.exitstatus.should == 0

    `sudo /usr/sbin/aeolus-configure`
    $?.exitstatus.should == 0

    ENV['RAILS_ENV'] = 'production'
    $: << "#{CONDUCTOR_PATH}/dutils"
    require "dutils"
  end

  after(:each) do
     remove_puppet_manifest
  end

  SPEC_MANIFEST = '/tmp/aeolus-spec.pp'

  def create_puppet_manifest(content)
    File.open(SPEC_MANIFEST, 'w') { |f| f.write content }
  end

  def remove_puppet_manifest
    FileUtils.rm SPEC_MANIFEST if File.exist? SPEC_MANIFEST
  end

  def run_puppet_manifest
    `sudo puppet #{SPEC_MANIFEST} --modulepath=/usr/share/aeolus-configure/modules/`
  end

  REQUEST_PREREQS = "$enable_https = true\n"+
                    "include aeolus::conductor\n" +
                    "aeolus::conductor::site_admin{'admin': email => 'dcuser@aeolusproject.org', password => 'password', first_name => 'aeolus', last_name => 'user'}\n" +
                    "aeolus::conductor::login{'admin': password => 'password', require => Aeolus::Conductor::Site_admin['admin']}\n"

  it "should allow provider creation and deletion" do
    create_puppet_manifest(REQUEST_PREREQS + 
                           "aeolus::provider{'mock3010': type => 'mock', port => 3010, require => Aeolus::Conductor::Login['admin'] }\n" +
                           "aeolus::conductor::logout{'admin':   require => Aeolus::Provider['mock3010'] }")
                           
    run_puppet_manifest
    $?.exitstatus.should == 0
    Provider.find(:first, :conditions => ['name = ?', 'mock3010']).should_not be_nil, "provider mock3010 should not be nil"
    # TODO actually verify service is running
    remove_puppet_manifest

    create_puppet_manifest(REQUEST_PREREQS +
                           "aeolus::deltacloud::disabled{'mock3010': }\n" +
                           "aeolus::conductor::logout{'admin':   require => Aeolus::Deltacloud::Disabled['mock3010'] }")
    run_puppet_manifest
    $?.exitstatus.should == 0
    #Provider.find(:first, :conditions => ['name = ?', 'mock3010']).should be_nil, "provider mock3010 should be nil"
    # TODO actually verify service is down
    remove_puppet_manifest
  end

  it "should allow new provider account creation" do
    create_puppet_manifest(REQUEST_PREREQS +
                           "aeolus::provider{'mock3020': type => 'mock', port => 3020, require => Aeolus::Conductor::Login['admin'] }\n" +
                           "aeolus::conductor::provider::account{'mockuser3020': provider => 'mock3020', type => 'mock', username => 'mockuser', password => 'mockpassword', require => Aeolus::Provider['mock3020'] }\n" +
                           "aeolus::conductor::logout{'admin':   require => Aeolus::Conductor::Provider::Account['mockuser3020'] }\n")
    run_puppet_manifest
    $?.exitstatus.should == 0
    p = Provider.find(:first, :conditions => ['name = ?', 'mock3020'])
    pa = p.provider_accounts.first
    pa.credentials.size.should == 2
    pa.credentials[0].value.should == "mockuser"
    pa.credentials[1].value.should == "mockpassword"
    remove_puppet_manifest

    create_puppet_manifest(REQUEST_PREREQS +
                           "aeolus::deltacloud::disabled{'mock3020':}\n" +
                           "aeolus::conductor::logout{'admin':   require => Aeolus::Deltacloud::Disabled['mock3020'] }\n")
    run_puppet_manifest
  end

  it "should allow new hwp creation" do
    create_puppet_manifest(REQUEST_PREREQS +
                           "aeolus::conductor::hwp{'hwp123': memory => '512', cpu => '1', storage => '1', architecture => 'x86_64', require => Aeolus::Conductor::Login['admin'] }\n" +
                           "aeolus::conductor::logout{'admin':   require => Aeolus::Conductor::Hwp['hwp123'] }\n")
    run_puppet_manifest
    $?.exitstatus.should == 0
    HardwareProfile.find(:first, :conditions => ['name = ?', 'hwp123']).should_not be_nil, "hwp123 should not be nil"
    remove_puppet_manifest

    create_puppet_manifest(REQUEST_PREREQS +
                           "aeolus::deltacloud::disabled{'mock3020': }\n" +
                           "aeolus::conductor::logout{'admin':   require => Aeolus::Deltacloud::Disabled['mock3020'] }\n")
    run_puppet_manifest
  end

  it "should allow new image creation" do
     create_puppet_manifest(REQUEST_PREREQS +
                            "aeolus::provider{'mock3030': type => 'mock', port => 3030, require => Aeolus::Conductor::Login['admin'] }\n" +
                            "aeolus::conductor::provider::account{'mockuser3030': provider => 'mock3030', type => 'mock', username => 'mockuser', password => 'mockpassword', require => Aeolus::Provider['mock3030'] }\n" +
                            "aeolus::conductor::hwp{'hwp234': memory => '1', cpu => '1', storage => '1', architecture => 'x86_64', require => Aeolus::Conductor::Login['admin'] }" +
                            "aeolus::image{image543: target => 'mock', template => 'examples/custom_repo.tdl', provider =>  'mock3030',\n" +
                            "   require  =>  [Aeolus::Conductor::Provider::Account['mockuser3030'], Aeolus::Conductor::Hwp['hwp234']] }\n" +
                            "aeolus::conductor::logout{'admin':   require => Aeolus::Image['image543'] }\n")
    run_puppet_manifest
    $?.exitstatus.should == 0

    # verify deployable
    File.exist?('/var/www/html/deployables/image543.xml').should be_true
    (File.read('/var/www/html/deployables/image543.xml') =~ /.*image id='([a-fA-F0-9\-]*)'.*/).should be_true
    build = $1

    # verify image in iwhd
    r = Curl::Easy.http_get 'http://localhost:9090/images'
    (r.body_str =~ /.*<key>#{build}<\/key>.*/).should be_true

    # verify deployment and instance in conductor
    # TODO verify instance is in 'running' state
    Deployment.find(:first, :conditions => ['name = ?', 'image543']).should_not be_nil
    Instance.find(:first, :conditions => ['name = ?', 'image543/image543']).should_not be_nil

    remove_puppet_manifest

    create_puppet_manifest(REQUEST_PREREQS +
                           "aeolus::deltacloud::disabled{'mock3030': }\n" +
                           "aeolus::conductor::logout{'admin':   require => Aeolus::Deltacloud::Disabled['mock3030'] }\n")
    run_puppet_manifest
  end
end
