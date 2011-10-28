%global aeolushome /usr/share/aeolus-configure
%global pbuild %{_builddir}/%{name}-%{version}

Summary:  Aeolus Configure Puppet Recipe
Name:     aeolus-configure
Version:  2.3.0
Release:  0%{?extra_release}%{?dist}

Group:    Applications/Internet
License:  ASL 2.0
URL:      http://aeolusproject.org

# to build source tarball
# git clone git://git.fedorahosted.org/aeolus/configure.git
# cd configure
# rake pkg
# cp pkg/aeolus-configure-2.0.1.tgz ~/rpmbuild/SOURCES
Source0:  %{name}-%{version}.tgz
BuildArch:  noarch
Requires:   puppet >= 2.6.6
Requires:   rubygem(uuidtools)
BuildRequires: rubygem(rspec-core)
# To send a request to iwhd rest interface to
# create buckets, eventually replace w/ an
# iwhd client
Requires:  curl
Requires:  rubygem(curb)
Requires:  rubygem(highline)

%description
Aeolus Configure Puppet Recipe

%prep
%setup -q

%build

%install
%{__mkdir} -p %{buildroot}/%{aeolushome}/modules/aeolus %{buildroot}/%{_sbindir}
%{__mkdir} -p %{buildroot}/%{_bindir}
%{__mkdir} -p %{buildroot}%{_sysconfdir}/aeolus-configure/nodes
%{__cp} -R %{pbuild}/conf/* %{buildroot}%{_sysconfdir}/aeolus-configure/nodes
%{__mv} %{buildroot}%{_sysconfdir}/aeolus-configure/nodes/custom_template.tdl %{buildroot}%{_sysconfdir}/aeolus-configure/
%{__cp} -R %{pbuild}/recipes/aeolus/* %{buildroot}/%{aeolushome}/modules/aeolus
%{__cp} -R %{pbuild}/recipes/apache/ %{buildroot}/%{aeolushome}/modules/apache
%{__cp} -R %{pbuild}/recipes/ntp/ %{buildroot}/%{aeolushome}/modules/ntp
%{__cp} -R %{pbuild}/recipes/openssl/ %{buildroot}/%{aeolushome}/modules/openssl
%{__cp} -R %{pbuild}/recipes/postgres/ %{buildroot}/%{aeolushome}/modules/postgres
%{__cp} -R %{pbuild}/bin/aeolus-node %{buildroot}/%{aeolushome}/modules/aeolus/
%{__cp} -R %{pbuild}/bin/aeolus-check-services %{buildroot}/%{_bindir}/
%{__cp} -R %{pbuild}/bin/aeolus-restart-services %{buildroot}/%{_sbindir}/
%{__cp} -R %{pbuild}/bin/aeolus-configure-image %{buildroot}/%{_sbindir}/
%{__cp} -R %{pbuild}/bin/aeolus-configure %{buildroot}/%{_sbindir}/
%{__cp} -R %{pbuild}/bin/aeolus-cleanup %{buildroot}/%{_sbindir}/

%files
%doc COPYING
%attr(0755, root, root) %{_sbindir}/aeolus-configure
%attr(0755, root, root) %{_sbindir}/aeolus-cleanup
%config(noreplace) %{_sysconfdir}/aeolus-configure/*
%attr(0755, root, root) %{_bindir}/aeolus-check-services
%attr(0755, root, root) %{_sbindir}/aeolus-restart-services
%{aeolushome}
%{_sbindir}/aeolus-configure-image

%changelog
* Wed Sep 14 2011 Richard Su <rwsu@redhat.com> 2.0.2-4
- single deltacloud-core
- rhevm and vsphere configurations moved to their own profiles
- wait 1 sec after deltacloud-core service startup before providers are added

* Tue Aug 30 2011 Maros Zatko <mzatko@redhat.com> 2.0.2-3
- Added script for restarting running services

* Tue Aug 16 2011 Maros Zatko <mzatko@redhat.com> 2.0.2-2
- Added script for listing running services

* Wed Aug 03 2011 Mo Morsi <mmorsi@redhat.com> 2.0.2-1
- update to include profiles, interactive installer

* Wed Jul 20 2011 Mo Morsi <mmorsi@redhat.com> 2.0.1-2
- updates to conform to Fedora package guidelines

* Tue Jul 19 2011 Mike Orazi <morazi@redhat.com> 2.0.1-1
- vSphere configuration
- RHEV configuration
- warehouse sync, solr, and factory connector services removed
- bug fixes

* Wed May 18 2011 Mike Orazi <morazi@redhat.com> 2.0.1-0
- Move using external nodes so changes to behavior can happen in etc

* Wed May 18 2011 Chris Lalancette <clalance@redhat.com> - 2.0.0-11
- Bump the release version

* Tue Mar 22 2011 Angus Thomas <athomas@redhat.com> 2.0.0-5
- Removed iwhd init script and config file

* Wed Feb 17 2011 Mohammed Morsi <mmorsi@redhat.com> 2.0.0-3
- renamed deltacloud-configure to aeolus-configure

* Tue Feb 15 2011 Mohammed Morsi <mmorsi@redhat.com> 2.0.0-3
- various fixes to recipe

* Thu Jan 14 2011 Mohammed Morsi <mmorsi@redhat.com> 2.0.0-2
- include openssl module


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

