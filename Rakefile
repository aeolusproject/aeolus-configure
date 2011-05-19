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
  rpm.package_files.include("bin/*", "recipes/**/*", "conf/*")
  rpm.topdir = "#{RPMBUILD_DIR}"
end

# Construct yum repo
Rake::YumTask.new(YUM_REPO) do |repo|
  repo.rpms << rpm_task.rpm_file
end

desc "Run configure spec tests locally"
Spec::Rake::SpecTask.new(:configure_spec) do |t|
  t.spec_files = FileList['spec/configure_spec.rb']
end

desc "Run cleanup spec tests locally"
Spec::Rake::SpecTask.new(:cleanup_spec) do |t|
  t.spec_files = FileList['spec/cleanup_spec.rb']
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
