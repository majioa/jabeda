Name: yabeda
Version: 0.0.1
Release: alt1

Summary: Yabeda OVZ complainer.
License: GPLv3
Group: System/Base
Url: http://yabeda.cryo.net.ru

Packager: Pavlov Konstantin <thresh@altlinux.ru>

Requires: libruby >= 1.8-alt3
Requires: ruby-module-debug
Requires: ruby-tmail

Source: %name-%version.tar.bz2

BuildRequires: libruby-devel ruby-stdlibs ruby

%description
Yabeda is an OpenVZ failcnt complainer which tends to be lightweight, flexible
and easily extendable.

Should be used on host machines (via some cron-job) to generate alerts when
failcnt gets increased. Failcnt is the counter used in openvz kernels to tell
whether the needed parameter reached its limit.

%prep
%setup -q

%install
mkdir -p %buildroot%_localstatedir/yabeda
mkdir -p %buildroot%_sysconfdir/cron.d
mkdir -p %buildroot%_sysconfdir/yabeda
mkdir -p %buildroot%_sbindir
install -pm 750 yabeda.rb %buildroot%_sbindir/yabeda
install -pm 640 yabeda.conf %buildroot%_sysconfdir/yabeda/yabeda.conf
install -pm 644 yabeda.cron %buildroot%_sysconfdir/cron.d/yabeda
touch %buildroot%_localstatedir/yabeda/state

%files
%_sysconfdir/cron.d/yabeda
%_sbindir/yabeda
%_localstatedir/yabeda
%dir %_sysconfdir/yabeda
%config %_sysconfdir/yabeda/yabeda.conf

%changelog
* Tue Feb 05 2008 Pavlov Konstantin <thresh@altlinux.ru> 0.0.1-alt1
- 0.0.1 release.

