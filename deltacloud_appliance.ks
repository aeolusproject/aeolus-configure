# Deltacloud appliance kickstart

# Yum repos to use
repo --name=f13         --mirrorlist=http://mirrors.fedoraproject.org/mirrorlist?repo=fedora-13&arch=$basearch
repo --name=f13-updates --mirrorlist=http://mirrors.fedoraproject.org/mirrorlist?repo=updates-released-f13&arch=$basearch
repo --name=thincrust   --baseurl=http://www.thincrust.net/repo/noarch/

# deltacloud yum repos:
#  * ruby 1.8.7
#  * rails 2.3.8
#  * patched activerecord, haml, and puppet rpms (to fix issues)
#  * deltacloud aggregator rpms
#  * condor-dcloud and libdeltacloud
#  * hail
repo --name=deltacloud_arch   --baseurl=http://repos.fedorapeople.org/repos/deltacloud/appliance/fedora-13/$basearch
repo --name=deltacloud_noarch --baseurl=http://repos.fedorapeople.org/repos/deltacloud/appliance/fedora-13/noarch

repo --name=deltacloud_local  --baseurl=file://DELTACLOUD_APPLIANCE_LOCAL_REPO

# pull pulp in from here
repo --name=pulp --baseurl=http://repos.fedorapeople.org/repos/pulp/pulp/fedora-13/$basearch/

# Firewall / network configuration
firewall --enable --ssh
network  --bootproto=dhcp --device=eth0 --onboot=on

# System authorization information
auth --useshadow --enablemd5

# System keyboard
keyboard us

# System language
lang en_US.UTF-8

# System timezone
timezone  US/Eastern

# System bootloader configuration
bootloader --append="5 console=tty0 console=ttyS0,115200" --location=mbr --timeout=1

# Disk partitioning information
part /  --fstype="ext3" --ondisk=sda --size=3072

# No need for additional config
firstboot --disable

%post
  /sbin/chkconfig --level 35 ace on
  mkdir /etc/sysconfig/ace
  echo deltacloud_appliance >> /etc/sysconfig/ace/appliancename

  # start mongodb and httpd for pulp server
  /sbin/chkconfig --level 35 mongod on
  /sbin/chkconfig --level 35 httpd on
%end

%packages --excludedocs --nobase --instLangs=en
@core
@base-x
@gnome-desktop
acpid
bash
chkconfig
dhclient
e2fsprogs
git
gnuplot
grub
guestfish
iputils
libguestfs
kernel
lokkit
parted
passwd
rootfiles
rpmdevtools
rubygem-boxgrinder-build
rubygem-boxgrinder-build-centos-os-plugin
rubygem-boxgrinder-build-ec2-platform-plugin
rubygem-boxgrinder-build-fedora-os-plugin
rubygem-boxgrinder-build-local-delivery-plugin
rubygem-boxgrinder-build-rhel-os-plugin
rubygem-boxgrinder-build-rpm-based-os-plugin
rubygem-boxgrinder-build-s3-delivery-plugin
rubygem-boxgrinder-build-sftp-delivery-plugin
rubygem-boxgrinder-build-vmware-platform-plugin
rubygem-boxgrinder-core
rubygem-spqr
rubygem-uuid
ruby-libguestfs
vim-enhanced
wget
bind-utils
sudo
qpidc
qpidd
yum
yum-utils
firefox
-authconfig
-checkpolicy
-dmraid
-ed
-fedora-logos
-fedora-release-notes
-kbd
-kpartx
-kudzu
-libselinux
-libselinux-python
-lvm2
-mdadm
-policycoreutils
-prelink
-selinux-policy*
-setserial
-tar
-usermode
-wireless-tools
-firstboot

deltacloud_appliance
%end
