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

AEOLUS_DEPENDENCY_PACKAGES = ['rubygem-aws', 'curl', 'java-1.6.0-openjdk', 'openssh-server',
                              'appliance-tools', 'livecd-tools', 'python-imgcreate']

# TODO want to include httpd, qpidd here as well but that requires elevated permissions
AEOLUS_DEPENDENCY_SERVICES = ['mongod', 'sshd', 'postgresql']

IWHD_URI='http://localhost:9090/'

CONDUCTOR_URI='http://localhost/conductor'

CONDUCTOR_PATH='/usr/share/aeolus-conductor'

