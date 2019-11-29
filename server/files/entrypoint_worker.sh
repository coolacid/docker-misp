#!/bin/bash

CAKE_CMD="/var/www/MISP/app/Console/cake CakeResque.CakeResque start --interval 5 --log-handler Console --queue "


# Wait until entrypoint apache is ready
while (true)
do
    sleep 2
    [ -f /entrypoint_apache.install ] && continue
    break
done

# start Worker for MISP
echo "Start Workers $1..."
$CAKE_CMD $1
