require 'rubygems'
require 'spec'
require 'spec/autorun'

$test_scripts = ENV['test_scripts']
$test_scripts = ($test_scripts != "false" && $test_scripts != "n")

AEOLUS_PACKAGES = ['iwhd', 'imagefactory',
                   'rubygem-deltacloud-core', 'rubygem-deltacloud-client',
                   'aeolus-conductor', 'aeolus-conductor-doc', 'aeolus-conductor-daemons',
                   'aeolus-configure']

AEOLUS_SERVICES = ['iwhd', 'deltacloud-mock', 'deltacloud-ec2-us-east-1', 'deltacloud-ec2-us-west-1', 'imagefactory',
                   'aeolus-conductor', 'conductor-condor_refreshd', 'conductor-dbomatic']
                   # 'conductor-delayed_job'] TODO where is the init script for this?

AEOLUS_DEPENDENCY_PACKAGES = ['rubygem-aws', 'curl', 'java-1.6.0-openjdk', 'openssh-server',
                              'rubygem-boxgrinder-build-ec2-platform-plugin', 'rubygem-boxgrinder-build-ec2-platform-plugin', 'rubygem-boxgrinder-build-rhel-os-plugin', 'rubygem-boxgrinder-build-rpm-based-os-plugin',
                              'appliance-tools', 'livecd-tools', 'python-imgcreate']

# TODO want to include httpd, qpidd here as well but that requires elevated permissions
AEOLUS_DEPENDENCY_SERVICES = ['mongod', 'condor', 'solr', 'sshd', 'postgresql']

IWHD_URI='http://localhost:9090/'

CONDUCTOR_URI='http://localhost/conductor'

CONDUCTOR_PATH='/usr/share/aeolus-conductor'

FIREWALL_OPEN_PORTS = [ '22', '80', '443', '5432' ]
