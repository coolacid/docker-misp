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

while true
do
    echo "Start Workers..."
    sudo -u www-data "$ENTRYPOINT_WORKERS_BIN_FILE"
    echo "Start Workers...finished"
    sleep 3600
done
