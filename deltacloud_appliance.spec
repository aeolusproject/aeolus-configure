%define aceHome /usr/share/ace
%define pbuild %{_builddir}/%{name}-%{version}

Summary:  DeltaCloud Appliance
Name:     deltacloud_appliance
Version:  0.0.1
Release:  1%{?dist}

Group:    Applications/Internet
License:  GPLv2+
URL:      http://deltacloud.org
Source0:  %{name}-%{version}.tar.gz
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
Requires:   pulp
Requires:   pulp-client

Requires:   rubygem-thin
Requires:   rubygem-haml

# To download the image builder, eventually replace with
# image builder rpm itself:
Requires:   wget

%description
Deltacloud appliance

%prep
%setup -q

%build

%install
rm -rf %{buildroot}
%{__mkdir} -p %{buildroot}/%{aceHome}/appliances/%{name}
%{__cp} -R %{pbuild}/* %{buildroot}/%{aceHome}/appliances/%{name}

%clean
rm -rf %{buildroot}

%files
%defattr(-,root,root,-)
%dir %{aceHome}
%{aceHome}/*


%changelog
* Thu Mar 26 2008 Mohammed Morsi <mmorsi@redhat.com> 0.0.1-1
- Initial package
