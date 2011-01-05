%define dchome /usr/share/deltacloud-recipe
%define pbuild %{_builddir}/%{name}-%{version}

Summary:  DeltaCloud Puppet Recipe
Name:     deltacloud_recipe
Version:  0.0.3
Release:  1%{?dist}

Group:    Applications/Internet
License:  GPLv2+
URL:      http://deltacloud.org
Source0:  %{name}-%{version}.tgz
BuildRoot:  %{_tmppath}/%{name}-%{version}
BuildArch:  noarch
Requires:   ruby

# To send a request to iwhd rest interface to
# create buckets, eventually replace w/ an
# iwhd client
Requires:  curl

%description
Deltacloud Puppet Recipe

%prep
%setup -q

%build

%install
rm -rf %{buildroot}
%{__mkdir} -p %{buildroot}/%{dchome}/modules/%{name} %{buildroot}/%{_sbindir}
%{__cp} -R %{pbuild}/recipes/%{name}/deltacloud_recipe.pp %{buildroot}/%{dchome}
%{__cp} -R %{pbuild}/recipes/%{name}/deltacloud_uninstall.pp %{buildroot}/%{dchome}
%{__cp} -R %{pbuild}/recipes/%{name}/*/ %{buildroot}/%{dchome}/modules/%{name}
%{__cp} -R %{pbuild}/recipes/firewall/ %{buildroot}/%{dchome}/modules/firewall
%{__cp} -R %{pbuild}/recipes/ntp/ %{buildroot}/%{dchome}/modules/ntp
%{__cp} -R %{pbuild}/recipes/postgres/ %{buildroot}/%{dchome}/modules/postgres
%{__cp} -R %{pbuild}/bin/dc-install %{buildroot}/%{_sbindir}/
%{__cp} -R %{pbuild}/bin/dc-uninstall %{buildroot}/%{_sbindir}/

%clean
rm -rf %{buildroot}

%files
%defattr(-,root,root,-)
%attr(0755, root, root) %{_sbindir}/dc-install
%attr(0755, root, root) %{_sbindir}/dc-uninstall
%{dchome}

%changelog
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
