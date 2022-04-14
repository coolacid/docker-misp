#!/bin/sh -e

# we only need to copy this in if the service is already running.
# if it's not running, it'll get picked up by the init script on start.
/etc/init.d/postfix status >/dev/null 2>&1 || exit 0

QUEUEDIR="$(/usr/sbin/postconf -h queue_directory 2>/dev/null || true)"
if [ -n "$QUEUEDIR" ]; then
    cp /etc/resolv.conf ${QUEUEDIR}/etc/resolv.conf
    /etc/init.d/postfix reload >/dev/null 2>&1 || exit 0
fi

exit 0
