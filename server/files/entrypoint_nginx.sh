#!/bin/bash

MISP_APP_CONFIG_PATH=/var/www/MISP/app/Config
[ -z "$MYSQL_HOST" ] && MYSQL_HOST=db
[ -z "$MYSQL_PORT" ] && MYSQL_PORT=3306
[ -z "$MYSQL_USER" ] && MYSQL_USER=misp
[ -z "$MYSQL_PASSWORD" ] && MYSQL_PASSWORD=example
[ -z "$MYSQL_DATABASE" ] && MYSQL_DATABASE=misp
[ -z "$REDIS_FQDN" ] && REDIS_FQDN=redis
[ -z "$MYSQLCMD" ] && MYSQLCMD="mysql -u $MYSQL_USER -p$MYSQL_PASSWORD -P $MYSQL_PORT -h $MYSQL_HOST -r -N  $MYSQL_DATABASE"

ENTRYPOINT_PID_FILE="/entrypoint_apache.install"
[ ! -f $ENTRYPOINT_PID_FILE ] && touch $ENTRYPOINT_PID_FILE

setup_cake_config(){
    sed -i "s/'host' => 'localhost'.*/'host' => '$REDIS_FQDN',          \/\/ Redis server hostname/" "/var/www/MISP/app/Plugin/CakeResque/Config/config.php"
}

init_misp_config(){
    [ -f $MISP_APP_CONFIG_PATH/bootstrap.php ] || cp $MISP_APP_CONFIG_PATH/bootstrap.default.php $MISP_APP_CONFIG_PATH/bootstrap.php
    [ -f $MISP_APP_CONFIG_PATH/database.php ] || cp $MISP_APP_CONFIG_PATH/database.default.php $MISP_APP_CONFIG_PATH/database.php
    [ -f $MISP_APP_CONFIG_PATH/core.php ] || cp $MISP_APP_CONFIG_PATH/core.default.php $MISP_APP_CONFIG_PATH/core.php
    [ -f $MISP_APP_CONFIG_PATH/config.php ] || cp $MISP_APP_CONFIG_PATH/config.default.php $MISP_APP_CONFIG_PATH/config.php

    echo "Configure MISP | Set DB User, Password and Host in database.php"
    sed -i "s/localhost/$MYSQL_HOST/" $MISP_APP_CONFIG_PATH/database.php
    sed -i "s/db\s*login/$MYSQL_USER/" $MISP_APP_CONFIG_PATH/database.php
    sed -i "s/db\s*password/$MYSQL_PASSWORD/" $MISP_APP_CONFIG_PATH/database.php

    echo "Configure sane defaults"
    /var/www/MISP/app/Console/cake Admin setSetting "MISP.redis_host" "$REDIS_FQDN"
    /var/www/MISP/app/Console/cake Admin setSetting "MISP.baseurl" "$HOSTNAME"
    /var/www/MISP/app/Console/cake Admin setSetting "MISP.python_bin" $(which python3)

    /var/www/MISP/app/Console/cake Admin setSetting "Plugin.ZeroMQ_enable" true
    /var/www/MISP/app/Console/cake Admin setSetting "Plugin.ZeroMQ_redis_host" "$REDIS_FQDN"

    /var/www/MISP/app/Console/cake Admin setSetting "Plugin.Enrichment_services_enable" true
    /var/www/MISP/app/Console/cake Admin setSetting "Plugin.Enrichment_services_url" "http://misp-modules"

    /var/www/MISP/app/Console/cake Admin setSetting "Plugin.Import_services_enable" true
    /var/www/MISP/app/Console/cake Admin setSetting "Plugin.Import_services_url" "http://misp-modules"

    /var/www/MISP/app/Console/cake Admin setSetting "Plugin.Export_services_enable" true
    /var/www/MISP/app/Console/cake Admin setSetting "Plugin.Export_services_url" "http://misp-modules"

    /var/www/MISP/app/Console/cake Admin setSetting "Plugin.Cortex_services_enable" false
}

init_misp_files(){
    if [ ! -f /var/www/MISP/app/files/INIT ]; then
        cp -R /var/www/MISP/app/files.dist/* /var/www/MISP/app/files
        touch /var/www/MISP/app/files/INIT
    fi
}

init_ssl() {
    if [[ (! -f /etc/ssl/certs/cert.pem) || (! -f /etc/ssl/certs/key.pem) ]];
    then
        cd /etc/ssl/certs
        openssl req -x509 -subj '/CN=localhost' -nodes -newkey rsa:4096 -keyout key.pem -out cert.pem -days 365
    fi
}

init_mysql(){
    # Test when MySQL is ready....
    # wait for Database come ready
    isDBup () {
        echo "SHOW STATUS" | $MYSQLCMD 1>/dev/null
        echo $?
    }

    RETRY=100
    until [ $(isDBup) -eq 0 ] || [ $RETRY -le 0 ] ; do
        echo "Waiting for database to come up"
        sleep 5
        RETRY=$(( RETRY - 1))
    done
    if [ $RETRY -le 0 ]; then
        >&2 echo "Error: Could not connect to Database on $MYSQL_HOST:$MYSQL_PORT"
        exit 1
    fi

    $MYSQLCMD < /var/www/MISP/INSTALL/MYSQL.sql
}

# Things we should do when we have the INITIALIZE Env Flag
if [[ "$INIT" == true ]]; then
    echo "Import MySQL scheme..." && init_mysql
    echo "Setup MISP files dir..." && init_misp_files
    echo "Ensure SSL certs exist..." && init_ssl
fi

# Things we should do if we're configuring MISP via ENV
echo "Initialize misp base config..." && init_misp_config

# Things that should ALWAYS happen
echo "Configure Cake | Change Redis host to $REDIS_FQDN ... " && setup_cake_config
echo "Configure MISP | Enforce permissions ..."
echo "... chown -R www-data.www-data /var/www/MISP ..." && find /var/www/MISP -not -user www-data -exec chown www-data.www-data {} +
echo "... chmod -R 0750 /var/www/MISP ..." && find /var/www/MISP -perm 550 -type f -exec chmod 0550 {} + && find /var/www/MISP -perm 770 -type d -exec chmod 0770 {} +
echo "... chmod -R g+ws /var/www/MISP/app/tmp ..." && chmod -R g+ws /var/www/MISP/app/tmp
echo "... chmod -R g+ws /var/www/MISP/app/files ..." && chmod -R g+ws /var/www/MISP/app/files
echo "... chmod -R g+ws /var/www/MISP/app/files/scripts/tmp ..." && chmod -R g+ws /var/www/MISP/app/files/scripts/tmp

# delete pid file
[ -f $ENTRYPOINT_PID_FILE ] && rm $ENTRYPOINT_PID_FILE

# Work around https://github.com/MISP/MISP/issues/5608
if [[ ! -f /var/www/MISP/PyMISP/pymisp/data/describeTypes.json ]]; then
    mkdir -p /var/www/MISP/PyMISP/pymisp/data/
    ln -s /usr/local/lib/python3.7/dist-packages/pymisp/data/describeTypes.json /var/www/MISP/PyMISP/pymisp/data/describeTypes.json
fi

# Start NGINX
nginx -g 'daemon off;'
