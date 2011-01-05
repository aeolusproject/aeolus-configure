# Deltacloud Recipe Rakefile

require 'rake/clean'
require 'rake/rpmtask'
require 'rake/yumtask'

CURRENT_DIR  = File.dirname(__FILE__)
RPMBUILD_DIR = "#{CURRENT_DIR}/build/rpmbuild"
YUM_REPO     = "#{CURRENT_DIR}/repo"

CLEAN.include('pkg', 'build', 'repo')
CLOBBER.include('deltacloud')
PKG_NAME = "deltacloud_recipe"
RPM_SPEC = "contrib/deltacloud_recipe.spec"

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
