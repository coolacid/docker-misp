#!/bin/bash

# Include default vars file:
# shellcheck disable=SC1091
source "/default_vars.sh"

# Wait until entrypoint NGINX is ready
while (true)
do
    sleep 2
    [ -f "$MISP_ENTRYPOINT_NGINX_PID_FILE" ] && continue
    break
done

# Create the misp cron tab
cat << EOF > /etc/cron.d/misp
20 2 * * * www-data $MISP_CAKE_FILE Server cacheFeed "$MISP_CRON_USER_ID" all >/tmp/cronlog 2>/tmp/cronlog
30 2 * * * www-data $MISP_CAKE_FILE Server fetchFeed "$MISP_CRON_USER_ID" all >/tmp/cronlog 2>/tmp/cronlog

00 3 * * * www-data $MISP_CAKE_FILE Admin updateGalaxies >/tmp/cronlog 2>/tmp/cronlog
10 3 * * * www-data $MISP_CAKE_FILE Admin updateTaxonomies >/tmp/cronlog 2>/tmp/cronlog
20 3 * * * www-data $MISP_CAKE_FILE Admin updateWarningLists >/tmp/cronlog 2>/tmp/cronlog
30 3 * * * www-data $MISP_CAKE_FILE Admin updateNoticeLists >/tmp/cronlog 2>/tmp/cronlog
45 3 * * * www-data $MISP_CAKE_FILE Admin updateObjectTemplates >/tmp/cronlog 2>/tmp/cronlog

EOF

if [ -n "$MISP_CRON_SYNCSERVERS" ];
then
    TIME=0
    for SYNCSERVER in $MISP_CRON_SYNCSERVERS
    do
cat << EOF >> /etc/cron.d/misp
$TIME 0 * * * www-data $MISP_CAKE_FILE Server pull "$MISP_CRON_USER_ID" "$SYNCSERVER">/tmp/cronlog 2>/tmp/cronlog
$TIME 1 * * * www-data $MISP_CAKE_FILE Server push "$MISP_CRON_USER_ID" "$SYNCSERVER">/tmp/cronlog 2>/tmp/cronlog
EOF

    ((TIME+=5))
    done
fi

# Build a fifo buffer for the cron logs, 777 so anyone can write to it
if [[ ! -p /tmp/cronlog ]]; then
    mkfifo /tmp/cronlog
fi
chmod 777 /tmp/cronlog

cron -f | tail -f /tmp/cronlog
