# Aeolus Configure/Recipe Rakefile

require 'rake/clean'
require 'rake/rpmtask'
require 'rake/yumtask'
require 'rubygems'
require 'spec/rake/spectask'

CURRENT_DIR  = File.dirname(__FILE__)
RPMBUILD_DIR = "#{File.expand_path('~')}/rpmbuild"
YUM_REPO     = "#{CURRENT_DIR}/repo"

CLEAN.include('pkg', 'repo')
CLOBBER.include('aeolus')
PKG_NAME = "aeolus-configure"
RPM_SPEC = "contrib/aeolus-configure.spec"

# Build the rpm
rpm_task =
Rake::RpmTask.new(RPM_SPEC) do |rpm|
  rpm.need_tar = true
  rpm.package_files.include("bin/*", "recipes/**/*")
  rpm.topdir = "#{RPMBUILD_DIR}"
end

# Construct yum repo
Rake::YumTask.new(YUM_REPO) do |repo|
  repo.rpms << rpm_task.rpm_file
end

desc "Run remote spec tests, SSH options: hostname=<hostname> username=<username> password=<password>"
Spec::Rake::SpecTask.new do |t|
  t.spec_files = FileList['spec/**/*_spec.rb']
end
