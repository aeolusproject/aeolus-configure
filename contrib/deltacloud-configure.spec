%define dchome /usr/share/deltacloud-configure
%define pbuild %{_builddir}/%{name}-%{version}

Summary:  DeltaCloud Configure Puppet Recipe
Name:     deltacloud-configure
Version:  2.0.0
Release:  2%{?dist}

Group:    Applications/Internet
License:  GPLv2+
URL:      http://deltacloud.org
Source0:  %{name}-%{version}.tgz
BuildRoot:  %{_tmppath}/%{name}-%{version}
BuildArch:  noarch
Requires:   puppet

# To send a request to iwhd rest interface to
# create buckets, eventually replace w/ an
# iwhd client
Requires:  curl

%description
Deltacloud Configure Puppet Recipe

%prep
%setup -q

%build

%install
rm -rf %{buildroot}
%{__mkdir} -p %{buildroot}/%{dchome}/modules/deltacloud_recipe %{buildroot}/%{_sbindir}
%{__cp} -R %{pbuild}/recipes/deltacloud_recipe/deltacloud_recipe.pp %{buildroot}/%{dchome}
%{__cp} -R %{pbuild}/recipes/deltacloud_recipe/deltacloud_uninstall.pp %{buildroot}/%{dchome}
%{__cp} -R %{pbuild}/recipes/deltacloud_recipe/*/ %{buildroot}/%{dchome}/modules/deltacloud_recipe
%{__cp} -R %{pbuild}/recipes/firewall/ %{buildroot}/%{dchome}/modules/firewall
%{__cp} -R %{pbuild}/recipes/ntp/ %{buildroot}/%{dchome}/modules/ntp
%{__cp} -R %{pbuild}/recipes/postgres/ %{buildroot}/%{dchome}/modules/postgres
%{__cp} -R %{pbuild}/bin/deltacloud-configure %{buildroot}/%{_sbindir}/
%{__cp} -R %{pbuild}/bin/deltacloud-cleanup %{buildroot}/%{_sbindir}/

%clean
rm -rf %{buildroot}

%files
%defattr(-,root,root,-)
%attr(0755, root, root) %{_sbindir}/deltacloud-configure
%attr(0755, root, root) %{_sbindir}/deltacloud-cleanup
%{dchome}

%changelog
* Mon Jan 10 2011 Mike Orazi <morazi@redhat.com> 2.0.0-1
- Make this a drop in replacement for the old deltacloud-configure scripts

* Wed Dec 22 2010 Mohammed Morsi <mmorsi@redhat.com> 0.0.4-1
- Revamp deltacloud recipe to make it more puppetized,
  use general purpose firewall, postgres, ntp modules,
  and to fix many various things

* Wed Sep 29 2010 Mohammed Morsi <mmorsi@redhat.com> 0.0.3-1
- Renamed package from deltacloud appliance
- to deltacloud recipe

* Wed Sep 29 2010 Mohammed Morsi <mmorsi@redhat.com> 0.0.2-3
- Include curl-devel for typhoeus gem

* Wed Sep 29 2010 Mohammed Morsi <mmorsi@redhat.com> 0.0.2-2
- Updated to pull in latest git changes

* Fri Sep 17 2010 Mohammed Morsi <mmorsi@redhat.com> 0.0.2-1
- Updated packages pulled in to latest versions
- Various fixes
- Added initial image warehouse bits

* Thu Sep 02 2010 Mohammed Morsi <mmorsi@redhat.com> 0.0.1-1
- Initial package
