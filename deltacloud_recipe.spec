%define aceHome /usr/share/ace
%define pbuild %{_builddir}/%{name}-%{version}

Summary:  DeltaCloud Appliance
Name:     deltacloud_appliance
Version:  0.0.2
Release:  3%{?dist}

Group:    Applications/Internet
License:  GPLv2+
URL:      http://deltacloud.org
Source0:  %{name}-%{version}.tgz
BuildRoot:  %{_tmppath}/%{name}-%{version}
BuildArch:  noarch
Requires:   ace-banners
Requires:   ace-ssh
Requires:   ace-postgres

# Deltacloud and dependencies
Requires:   deltacloud-aggregator
Requires:   deltacloud-aggregator-daemons
Requires:   deltacloud-aggregator-doc
Requires:   condor >=  7.5.0
Requires:   ruby
Requires:   ruby-rdoc
Requires:   ruby-devel
Requires:   rubygem-rails
Requires:   gcc-c++
Requires:   libxml2-devel
Requires:   libxslt-devel
Requires:   libcurl-devel
Requires:   pulp
Requires:   pulp-client

Requires:   rubygem-thin
Requires:   rubygem-haml

# To download the image builder and warehouse,
# eventually replace with the corresponding rpms
Requires:   wget

# To send a request to iwhd rest interface to
# create buckets, eventually replace w/ an
# iwhd client
Requires:  curl

# Image warehouse deps, remove when we pull in rpm
Requires: jansson
Requires: libmicrohttpd
Requires: hail
Requires: tokyocabinet
Requires: mongo

%description
Deltacloud appliance

%prep
%setup -q

%build

%install
rm -rf %{buildroot}
%{__mkdir} -p %{buildroot}/%{aceHome}/appliances/%{name}
%{__cp} -R %{pbuild}/%{name}/* %{buildroot}/%{aceHome}/appliances/%{name}

%clean
rm -rf %{buildroot}

%files
%defattr(-,root,root,-)
%dir %{aceHome}
%{aceHome}/*


%changelog
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
