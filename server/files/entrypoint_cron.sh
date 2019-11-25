#!/bin/sh
set -e

NC='\033[0m' # No Color
Light_Green='\033[1;32m'  
echo (){
    command echo -e $1
}

STARTMSG="${Light_Green}[ENTRYPOINT_CRON]${NC}"

# Wait until entrypoint apache is ready
while (true)
do
    sleep 2
    [ -f /entrypoint_apache.install ] && continue
    break
done

[ -n "$CRON_INTERVAL" ] && INTERVAL="$CRON_INTERVAL"
( [ -z "$CRON_INTERVAL" ] || [ "$CRON_INTERVAL" = 0 ] ) && echo "$STARTMSG Deactivate cron job." && exit
[ -z "$CRON_USER_ID" ] && USER_ID=1


# wait for the first round
echo "$STARTMSG Wait $INTERVAL seconds, then start the first intervall." && sleep "$INTERVAL" 
# start cron job
echo "$STARTMSG Start cron job" && misp_cron.sh "$INTERVAL" "$USER_ID"

