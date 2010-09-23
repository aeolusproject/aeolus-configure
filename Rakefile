# Deltacloud Appliance Rakefile

require 'rake/clean'
require 'rake/rpmtask'
require 'rake/yumtask'

CURRENT_DIR  = File.dirname(__FILE__)
RPMBUILD_DIR = "#{CURRENT_DIR}/build/rpmbuild"
YUM_REPO     = "#{CURRENT_DIR}/repo"

CLEAN.include('pkg', 'build', 'repo', 'deltacloud_appliance.ks.new')
CLOBBER.include('deltacloud')
PKG_NAME = "deltacloud_appliance"
RPM_SPEC = "deltacloud_appliance.spec"

task :default => :rpms

# Build the rpm
Rake::RpmTask.new(RPM_SPEC) do |rpm|
  rpm.need_tar = true
  rpm.package_files.include("#{PKG_NAME}/**/*")
  rpm.topdir = "#{RPMBUILD_DIR}"
end

# Construct yum repo
Rake::YumTask.new(YUM_REPO) do |repo|
  repo.rpms << "#{RPMBUILD_DIR}/RPMS/noarch/#{PKG_NAME}*.rpm"
end

desc "create image"
task :create_image => :create_repo do
 puts "NOTE:  This command will only work if run as root, so we're using 'sudo'.  You have been warned!"
 cp_r "deltacloud_appliance.ks", "deltacloud_appliance.ks.new"
 sh   "sed -i s-DELTACLOUD_APPLIANCE_LOCAL_REPO-#{YUM_REPO}- deltacloud_appliance.ks.new"
 system "sudo appliance-creator -n deltacloud -c deltacloud_appliance.ks.new --cache /var/tmp/act"
end
