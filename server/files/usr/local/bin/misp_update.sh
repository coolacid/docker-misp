#!/bin/bash

set -ex

NC='\033[0m' # No Color
Light_Green='\033[1;32m'  
echo (){
    command echo -e $1
}

STARTMSG="${Light_Green}[UPDATE_MISP]${NC}"


[ -z $CAKE ] && export CAKE="$MISP_APP_PATH/Console/cake"

# Init MISP and create user
while true
do
    # copy auth_key
    export AUTH_KEY=$(docker exec misp-server bash -c 'mysql -u $MYSQL_USER -p$MYSQL_PASSWORD $MYSQL_DATABASE -e "SELECT authkey FROM users;" | head -2|tail -1')
    
    # initial user if all is good auth_key is return
    [ -z $AUTH_KEY  ] && export AUTH_KEY=$(docker exec misp-server bash -c "sudo -E /var/www/MISP/app/Console/cake userInit -q") && echo "new Auth_Key: $AUTH_KEY"
    
    # if user is initalized but mysql is not ready continue
    [ "$AUTH_KEY" == "Script aborted: MISP instance already initialised." ] && continue
    
    # if the auth_key is save go out 
    [ -z $AUTH_KEY ] || break
        
    # wait 5 seconds
    sleep 5
done



# Update the galaxies…
echo "$STARTMSG Update Galaxies..." && sudo "$CAKE" Admin updateGalaxies
# Updating the taxonomies…
echo "$STARTMSG Update Taxonomies..." && sudo "$CAKE" Admin updateTaxonomies
# Updating the warning lists…
echo "$STARTMSG Update WarningLists..." && sudo "$CAKE" Admin updateWarningLists
# Updating the notice lists…
echo "$STARTMSG Update NoticeLists..." && sudo "$CAKE" Admin updateNoticeLists
#curl --header "Authorization: $AUTH_KEY" --header "Accept: application/json" --header "Content-Type: application/json" -k -X POST https://127.0.0.1/noticelists/update

# Updating the object templates…
echo "$STARTMSG Update Object Templates..." && sudo "$CAKE" Admin updateObjectTemplates
#curl --header "Authorization: $AUTH_KEY" --header "Accept: application/json" --header "Content-Type: application/json" -k -X POST https://127.0.0.1/objectTemplates/update

exit