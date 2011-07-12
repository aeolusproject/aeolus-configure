require 'rubygems'
require 'spec'
require 'spec/autorun'

$test_scripts = ENV['test_scripts']
$test_scripts = ($test_scripts != "false" && $test_scripts != "n")

AEOLUS_PACKAGES = ['iwhd', 'imagefactory',
                   'deltacloud-core', 'rubygem-deltacloud-client',
                   'aeolus-conductor', 'aeolus-conductor-daemons',
                   'aeolus-configure']

AEOLUS_SERVICES = ['iwhd', 'deltacloud-mock', 'deltacloud-ec2-us-east-1', 'deltacloud-ec2-us-west-1', 'imagefactory',
                   'aeolus-conductor', 'conductor-dbomatic']
                   # 'conductor-delayed_job'] TODO where is the init script for this?

AEOLUS_DEPENDENCY_PACKAGES = ['rubygem-aws', 'curl', 'java-1.6.0-openjdk', 'openssh-server',
                              'appliance-tools', 'livecd-tools', 'python-imgcreate']

# TODO want to include httpd, qpidd here as well but that requires elevated permissions
AEOLUS_DEPENDENCY_SERVICES = ['mongod', 'condor', 'sshd', 'postgresql']

IWHD_URI='http://localhost:9090/'

CONDUCTOR_URI='http://localhost/conductor'

CONDUCTOR_PATH='/usr/share/aeolus-conductor'

