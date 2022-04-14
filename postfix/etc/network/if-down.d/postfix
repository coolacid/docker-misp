#!/bin/sh -e

# Called when an interface disconnects
# Written by LaMont Jones <lamont@debian.org>

# start or reload Postfix as needed

# If /usr isn't mounted yet, silently bail.
if [ ! -d /usr/lib/postfix ]; then
	exit 0
fi

RUNNING=""
# If master is running, force a queue run to unload any mail that is
# hanging around.  Yes, sendmail is a symlink...
if [ -f /var/spool/postfix/pid/master.pid ]; then
	pid=$(sed 's/ //g' /var/spool/postfix/pid/master.pid)
	exe=$(ls -l /proc/$pid/exe 2>/dev/null | sed 's/.* //;s/.*\///')
	if [ "X$exe" = "Xmaster" ]; then
		RUNNING="y"
	fi
fi

if [ ! -x /sbin/resolvconf ]; then
	f=/etc/resolv.conf
	if ! cp $f $(postconf -h queue_directory)$f 2>/dev/null; then
		exit 0
	fi
	if [ -n "$RUNNING" ]; then
		/etc/init.d/postfix reload >/dev/null 2>&1
	fi
fi

exit 0
