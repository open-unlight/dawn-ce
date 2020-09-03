#!/bin/sh

install -m644 ../flashpolicy.xml /usr/local/etc/
install -m755 in.flashpolicyd.pl /usr/local/sbin/
install -m644 flashpolicyd.xinet /etc/xinetd.d/flashpolicyd
sh -c "cat cdpservice >> /etc/services"
/etc/init.d/xinetd reload
perl -e 'printf "<policy-file-request/>%c",0' | nc 127.0.0.1 11999
exit 0
