# Deltacloud Appliance Rakefile

require 'rake/clean'
require 'rake/rpmtask'
require 'rake/yumtask'

CURRENT_DIR  = File.dirname(__FILE__)
RPMBUILD_DIR = "#{CURRENT_DIR}/build/rpmbuild"
YUM_REPO     = "#{CURRENT_DIR}/repo"

CLEAN.include('pkg', 'build', 'repo', 'deltacloud_appliance.ks.new')
CLOBBER.include('deltacloud')
PKG_NAME = "deltacloud_recipe"
RPM_SPEC = "deltacloud_recipe.spec"

task :default => :"image:create"

# Build the rpm
Rake::RpmTask.new(RPM_SPEC) do |rpm|
  rpm.need_tar = true
  rpm.package_files.include("bin/*", "#{PKG_NAME}/**/*")
  rpm.topdir = "#{RPMBUILD_DIR}"
end

# Construct yum repo
Rake::YumTask.new(YUM_REPO) do |repo|
  repo.rpms << "#{RPMBUILD_DIR}/RPMS/noarch/#{PKG_NAME}*.rpm"
end

namespace "image" do
  desc "create appliance image"
  task :create => :create_repo do |t,args|
    puts "NOTE:  This command will only work if run as root, so we're using 'sudo'.  You have been warned!"
    cp_r "deltacloud_appliance.ks", "deltacloud_appliance.ks.new"
    sh   "sed -i s-DELTACLOUD_APPLIANCE_LOCAL_REPO-#{YUM_REPO}- deltacloud_appliance.ks.new"
    if File.exists?("deltacloud") && args.force.nil?
      puts "Appliance exist, specify 'force=true' to overwrite"
    else
      sh "sudo appliance-creator -n deltacloud -c deltacloud_appliance.ks.new --vmem 1024 --cache /var/tmp/act"
    end
  end

  desc "deploy appliance from image"
  task :deploy => :create do
    puts "NOTE:  These commands will only work if run as root, so we're using 'sudo'.  You have been warned!"
    system "sudo virsh domuuid deltacloud"
    if $? == 0
      puts "Deltacloud appliance already defined, delete with 'rake image:destroy'"
    else
      sh "sudo virt-image deltacloud/deltacloud.xml"
      sh "sudo virsh start deltacloud"
      sh "sudo virt-viewer deltacloud"
    end
  end

  desc "destroy appliance and image"
  task :destroy do
    puts "NOTE:  These commands will only work if run as root, so we're using 'sudo'.  You have been warned!"
    system "sudo virsh domuuid deltacloud"
    if $? == 0
      system "sudo virsh destroy deltacloud"
      sh "sudo virsh undefine deltacloud"
    end
    if File.exists?("deltacloud")
      sh "sudo rm -rf deltacloud"
    end
  end
end
