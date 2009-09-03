Name: yabeda
Version: 0.0.6
Release: alt2

Summary: Yabeda OVZ complainer.
License: GPLv3
Group: System/Base
Url: http://www.assembla.com/wiki/show/yabeda

Packager: Pavlov Konstantin <thresh@altlinux.ru>

Source: %name-%version.tar.bz2

BuildArch: noarch

Requires: ruby ruby-dbi mysql-ruby xmpp4r ruby-tmail

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
%dir %_localstatedir/yabeda
%attr(600,root,root) %_localstatedir/yabeda/state
%dir %_sysconfdir/yabeda
%config %_sysconfdir/yabeda/yabeda.conf

%changelog
* Thu Sep 03 2009 Pavlov Konstantin <thresh@altlinux.ru> 0.0.6-alt2
- Fix syntax for ruby 1.9.
- Fix #18785.

* Fri May 15 2009 Pavlov Konstantin <thresh@altlinux.ru> 0.0.6-alt1
- 0.0.6 release.

* Fri Aug 29 2008 Pavlov Konstantin <thresh@altlinux.ru> 0.0.5-alt1
- 0.0.5 release.

* Fri Jul 04 2008 Pavlov Konstantin <thresh@altlinux.ru> 0.0.4-alt1
- 0.0.4 release.

* Wed Jun 25 2008 Pavlov Konstantin <thresh@altlinux.ru> 0.0.3-alt1
- 0.0.3 release.

* Thu May 15 2008 Pavlov Konstantin <thresh@altlinux.ru> 0.0.2-alt1
- 0.0.2 release.

* Tue Feb 05 2008 Pavlov Konstantin <thresh@altlinux.ru> 0.0.1-alt1
- 0.0.1 release.

