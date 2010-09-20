require 'rake/clean'
require 'rake/packagetask'

directory 'build/rpmbuild/SOURCES'
directory 'build/rpmbuild/SPECS'
directory 'build/rpmbuild/SRPMS'
directory 'build/rpmbuild/RPMS/noarch'
directory 'build/rpmbuild/BUILD'
directory 'repo/noarch'
directory 'repo/x86_64'

CLEAN.include('pkg', 'build/**')
CLOBBER.include('deltacloud/**', 'repo/**')
PKG_NAME = "deltacloud_appliance"
PKG_VERSION = "0.0.2"
RPM_TOPDIR = "_topdir #{Dir.pwd}/build/rpmbuild"

task :default => :rpm

#Make the tarball
Rake::PackageTask.new("#{PKG_NAME}", "#{PKG_VERSION}") do |p|
 p.need_tar = true
 p.package_files.include("#{PKG_NAME}/**")
end

desc "build the rpm"
task :rpm => ["pkg/#{PKG_NAME}-#{PKG_VERSION}.tgz", 
       "build/rpmbuild/SOURCES", "build/rpmbuild/SPECS", "build/rpmbuild/SRPMS",
       "build/rpmbuild/RPMS/noarch", "build/rpmbuild/BUILD"] do
 cp "pkg/#{PKG_NAME}-#{PKG_VERSION}.tgz" ,  "build/rpmbuild/SOURCES/#{PKG_NAME}-#{PKG_VERSION}.tgz"
 cp "#{PKG_NAME}.spec", "build/rpmbuild/SPECS/#{PKG_NAME}.spec"

 system "rpmbuild --define \"#{RPM_TOPDIR}\" -ba #{PKG_NAME}.spec"
end

desc "Create a yum repo for the appliance"
task :create_repo => ["repo/noarch", "repo/x86_64", :rpm ] do
 cp_r "build/rpmbuild/RPMS/noarch/.", "repo/noarch", :verbose => true
 system "cd repo; createrepo -v ."
end

desc "create image"
task :create_image => :rpm do
 puts "NOTE:  This command will only work if run as root, so we're using 'sudo'.  You have been warned!"
 system "sudo appliance-creator -n deltacloud -c deltacloud_appliance.ks --cache /var/tmp/act"
end





 
