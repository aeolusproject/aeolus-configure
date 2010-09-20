# Deltacloud appliance kickstart

# Yum repos to use
repo --name=f13         --mirrorlist=http://mirrors.fedoraproject.org/mirrorlist?repo=fedora-13&arch=$basearch
repo --name=f13-updates --mirrorlist=http://mirrors.fedoraproject.org/mirrorlist?repo=updates-released-f13&arch=$basearch
repo --name=thincrust   --baseurl=http://www.thincrust.net/repo/noarch/

# local yum repo with:
#  * ruby 1.8.7
#  * rails 2.3.8
#  * patched activerecord, haml, and puppet rpms (to fix issues)
#  * deltacloud aggregator rpms
#  * condor-dcloud and libdeltacloud
#  * deltacloud_appliance
#  * hail
repo --name=deltacloud_local --baseurl=http://yum.morsi.org/repos/13

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
bootloader --append="5" --location=mbr --timeout=1

# Disk partitioning information
part /  --fstype="ext3" --ondisk=sda --size=3072 --bytes-per-inode=4096

# No need for additional config
firstboot --disable

%post
  /sbin/chkconfig --level 35 ace on
  mkdir /etc/sysconfig/ace
  echo deltacloud_appliance >> /etc/sysconfig/ace/appliancename

  # start mongodb and httpd for pulp server
  /sbin/chkconfig --level 35 mongod on
  /sbin/chkconfig --level 35 httpd on

  /usr/sbin/useradd dcuser -p ""
  # TODO (here or in deltacloud_appliance.pp) startup firefox on duser's X login w/ core & aggregator wuis in tabs
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
grub
iputils
kernel
lokkit
passwd
rootfiles
vim-enhanced
wget
bind-utils
yum
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
