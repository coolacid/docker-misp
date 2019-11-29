#!/bin/bash

CAKE_CMD="/var/www/MISP/app/Console/cake CakeResque.CakeResque startscheduler --interval 5 --log-handler Console"

# Wait until entrypoint apache is ready
while (true)
do
    sleep 2
    [ -f /entrypoint_apache.install ] && continue
    break
done

# start Worker for MISP
echo "Start Scheduler $1..."
$CAKE_CMD $1
