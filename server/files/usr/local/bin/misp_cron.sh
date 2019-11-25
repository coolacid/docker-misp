#!/bin/bash
set -e

NC='\033[0m' # No Color
Light_Green='\033[1;32m'  
echo (){
    command echo -e $1
}

COUNTER="$(date +%Y-%m-%d_%H:%M)"
STARTMSG="${Light_Green}[ENTRYPOINT_CRON] [ $COUNTER ] ${NC}"



if [ -z "$1" ] ; then
    # If Interval is empty set interval default to 3600s
    INTERVAL=3600
else
    INTERVAL="$1"
fi
if [ -z "$2" ] ; then
    # If Interval is empty set interval default to 3600s
    USER_ID=1
else
    USER_ID="$2"
fi


CAKE="/var/www/MISP/app/Console/cake"

[ -z "$MYSQL_DATABASE" ] && export MYSQL_DATABASE=misp
[ -z "$MYSQL_HOST" ] && export MYSQL_HOST=misp-db
[ -z "$MYSQL_ROOT_PASSWORD" ] && echo "$STARTMSG No MYSQL_ROOT_PASSWORD is set. Exit now." && exit 1
[ -z "$MYSQL_PORT" ] && export MYSQL_PORT=3306
[ -z "$MYSQL_USER" ] && export MYSQL_USER=misp
[ -z "$MYSQLCMD" ] && export MYSQLCMD="mysql -u $MYSQL_USER -p$MYSQL_PASSWORD -P $MYSQL_PORT -h $MYSQL_HOST -r -N  $MYSQL_DATABASE"

check_mysql_and_get_auth_key(){
    # Test when MySQL is ready    

    # wait for Database come ready
    isDBup () {
        echo "SHOW STATUS" | $MYSQLCMD 1>/dev/null
        echo $?
    }

    RETRY=10
    until [ $(isDBup) -eq 0 ] || [ $RETRY -le 0 ] ; do
        echo "Waiting for database to come up"
        sleep 5
        RETRY=$(( $RETRY - 1))
    done
    if [ $RETRY -le 0 ]; then
        >&2 echo "Error: Could not connect to Database on $MYSQL_HOST:$MYSQL_PORT"
        exit 1
    else
        # get AUTH_KEY
        export AUTH_KEY=$(echo "SELECT authkey FROM users where id = '$USER_ID';" | $MYSQLCMD)
    fi

}

# Wait until MySQL is ready and get the AUTH_KEXY
check_mysql_and_get_auth_key


while(true)
do
    # Administering MISP via the CLI
        # Certain administrative tasks are exposed to the API, these help with maintaining and configuring MISP in an automated way / via external tools.:
        # GetSettings: MISP/app/Console/cake Admin getSetting [setting]
        # SetSettings: MISP/app/Console/cake Admin getSetting [setting] [value]
        # GetAuthkey: MISP/app/Console/cake Admin getauthkey [email]
        # SetBaseurl: MISP/app/Console/cake Baseurl setbaseurl [baseurl]
        # ChangePassword: MISP/app/Console/cake Password [email] [new_password]

    # Automating certain console tasks
        # If you would like to automate tasks such as caching feeds or pulling from server instances, you can do it using the following command line tools. Simply execute the given commands via the command line / create cron jobs easily out of them.:
        # Pull: MISP/app/Console/cake Server pull [user_id] [server_id] [full|update]
        # Push: MISP/app/Console/cake Server push [user_id] [server_id]
        # CacheFeed: MISP/app/Console/cake Server cacheFeed [user_id] [feed_id|all|csv|text|misp]
        # FetchFeed: MISP/app/Console/cake Server fetchFeed [user_id] [feed_id|all|csv|text|misp]
        # Enrichment: MISP/app/Console/cake Event enrichEvent [user_id] [event_id] [json_encoded_module_list]

    # START the SCRIPT
        # Set time and date
    COUNTER="$(date +%Y-%m-%d_%H:%M)"

        # Start Message
    echo "$STARTMSG Start MISP-dockerized Cronjob at $COUNTER... "

    # Pull: MISP/app/Console/cake Server pull [user_id] [server_id] [full|update]
    echo "$STARTMSG $CAKE Server pull $USER_ID..." && $CAKE Server pull "$USER_ID"

    # Push: MISP/app/Console/cake Server push [user_id] [server_id]
    echo "$STARTMSG $CAKE Server push $USER_ID..." && $CAKE Server push "$USER_ID"

    # CacheFeed: MISP/app/Console/cake Server cacheFeed [user_id] [feed_id|all|csv|text|misp]
    echo "$STARTMSG $CAKE Server cacheFeed $USER_ID all..." && $CAKE Server cacheFeed "$USER_ID" all

    #FetchFeed: MISP/app/Console/cake Server fetchFeed [user_id] [feed_id|all|csv|text|misp]
    echo "$STARTMSG $CAKE Server fetchFeed $USER_ID all..." && $CAKE Server fetchFeed "$USER_ID" all
    
    # End Message
    echo "$STARTMSG Finished MISP-dockerized Cronjob at $(date +%Y-%m-%d_%H:%M) and wait $INTERVAL seconds... "
    
    # Wait this time
    sleep "$INTERVAL"
done