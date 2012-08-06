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

# Aeolus Configure/Recipe Rakefile

require 'rake/clean'
require './rake/rpmtask'
require './rake/yumtask'
require 'rubygems'
require 'rspec/core/rake_task'

CURRENT_DIR  = File.dirname(__FILE__)
RPMBUILD_DIR = "#{File.expand_path('~')}/rpmbuild"
YUM_REPO     = "#{CURRENT_DIR}/repo"

CLEAN.include('pkg', 'repo')
CLOBBER.include('aeolus')
PKG_NAME = "aeolus-configure"
RPM_SPEC = "contrib/aeolus-configure.spec"
PKG_VERSION = "2.8.1"

# Build the rpm
rpm_task =
Rake::RpmTask.new(RPM_SPEC, {:suffix => '.in', :pkg_version => PKG_VERSION}) do |rpm|
  rpm.need_tar = true
  rpm.package_files.include("COPYING", "bin/*", "recipes/**/*", "conf/*", "docs/**/*")
  rpm.topdir = "#{RPMBUILD_DIR}"
end

# Construct yum repo
Rake::YumTask.new(YUM_REPO) do |repo|
  repo.rpms << rpm_task.rpm_file
end

desc "Run configure spec tests locally"
RSpec::Core::RakeTask.new(:configure_spec) do |t|
  t.pattern = FileList['spec/configure_spec.rb']
end

desc "Run cleanup spec tests locally"
RSpec::Core::RakeTask.new(:cleanup_spec) do |t|
  t.pattern = FileList['spec/cleanup_spec.rb']
end

desc "Run seed spec tests locally"
RSpec::Core::RakeTask.new(:seed_spec) do |t|
  t.pattern = FileList['spec/seed_data_spec.rb']
end

begin
  require 'rake/remotespectask'

  desc "Run configure spec tests remotely"
  Rake::RemoteSpecTask.new(:remote_configure_spec) do |t|
    t.spec_files = FileList['spec/configure_spec.rb']
  end

  desc "Run cleanup spec tests remotely"
  Rake::RemoteSpecTask.new(:remote_cleanup_spec) do |t|
    t.spec_files = FileList['spec/cleanup_spec.rb']
  end
rescue LoadError
  # need net-ssh and net-scp needed to run remote specs
end
