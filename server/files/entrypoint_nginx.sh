#!/bin/bash

# Include default vars file:
# shellcheck disable=SC1091
source "/default_vars.sh"

# Check if installation is already done:
[ ! -f "$MISP_ENTRYPOINT_NGINX_PID_FILE" ] && touch "$MISP_ENTRYPOINT_NGINX_PID_FILE"

setup_cake_config(){
    sed -i "s/'host' => 'localhost'.*/'host' => '$MISP_REDIS_HOST',          \/\/ Redis server hostname/" "/var/www/MISP/app/Plugin/CakeResque/Config/config.php"
    sed -i "s/'host' => '127.0.0.1'.*/'host' => '$MISP_REDIS_HOST',          \/\/ Redis server hostname/" "/var/www/MISP/app/Plugin/CakeResque/Config/config.php"
}

init_misp_config(){
    [ -f "$MISP_MISP_APP_CONFIG_PATH/bootstrap.php" ] || cp "$MISP_MISP_APP_CONFIG_PATH.dist/bootstrap.default.php" "$MISP_MISP_APP_CONFIG_PATH/bootstrap.php"
    [ -f "$MISP_MISP_APP_CONFIG_PATH/database.php" ] || cp "$MISP_MISP_APP_CONFIG_PATH.dist/database.default.php" "$MISP_MISP_APP_CONFIG_PATH/database.php"
    [ -f "$MISP_MISP_APP_CONFIG_PATH/core.php" ] || cp "$MISP_MISP_APP_CONFIG_PATH.dist/core.default.php" "$MISP_MISP_APP_CONFIG_PATH/core.php"
    [ -f "$MISP_MISP_APP_CONFIG_PATH/config.php" ] || cp "$MISP_MISP_APP_CONFIG_PATH.dist/config.default.php" "$MISP_MISP_APP_CONFIG_PATH/config.php"
    [ -f "$MISP_MISP_APP_CONFIG_PATH/email.php" ] || cp "$MISP_MISP_APP_CONFIG_PATH.dist/email.php" "$MISP_MISP_APP_CONFIG_PATH/email.php"
    [ -f "$MISP_MISP_APP_CONFIG_PATH/routes.php" ] || cp "$MISP_MISP_APP_CONFIG_PATH.dist/routes.php" "$MISP_MISP_APP_CONFIG_PATH/routes.php"

    echo "Configure MISP | Set DB User, Password and Host in database.php"
    sed -i "s/localhost/$MISP_MYSQL_HOST/" "$MISP_MISP_APP_CONFIG_PATH/database.php"
    sed -i "s/db\s*login/$MISP_MYSQL_USER/" "$MISP_MISP_APP_CONFIG_PATH/database.php"
    sed -i "s/db\s*password/$MISP_MYSQL_PASSWORD/" "$MISP_MISP_APP_CONFIG_PATH/database.php"
    sed -i "s/'database' => */'database' => '$MISP_MYSQL_DB',/" "$MISP_MISP_APP_CONFIG_PATH/database.php"

    echo "Configure sane defaults"
    $MISP_CAKE_FILE Admin setSetting "MISP.redis_host" "$MISP_REDIS_HOST"
    $MISP_CAKE_FILE Admin setSetting "MISP.baseurl" "$MISP_MISP_BASEURL"
    $MISP_CAKE_FILE Admin setSetting "MISP.python_bin" $(which python3)

    $MISP_CAKE_FILE Admin setSetting "Plugin.ZeroMQ_redis_host" "$MISP_REDIS_HOST"
    $MISP_CAKE_FILE Admin setSetting "Plugin.ZeroMQ_enable" true

    $MISP_CAKE_FILE Admin setSetting "Plugin.Enrichment_services_enable" true
    $MISP_CAKE_FILE Admin setSetting "Plugin.Enrichment_services_url" "$MISP_MISPMODULES_FQDN"

    $MISP_CAKE_FILE Admin setSetting "Plugin.Import_services_enable" true
    $MISP_CAKE_FILE Admin setSetting "Plugin.Import_services_url" "$MISP_MISPMODULES_FQDN"

    $MISP_CAKE_FILE Admin setSetting "Plugin.Export_services_enable" true
    $MISP_CAKE_FILE Admin setSetting "Plugin.Export_services_url" "$MISP_MISPMODULES_FQDN"

    $MISP_CAKE_FILE Admin setSetting "Plugin.Cortex_services_enable" false
}

init_misp_files(){
    if [ ! -f /var/www/MISP/app/files/INIT ]; then
        cp -R /var/www/MISP/app/files.dist/* /var/www/MISP/app/files
        touch /var/www/MISP/app/files/INIT
    fi
}

init_ssl() {
    if [[ (! -f /etc/nginx/certs/cert.pem) || (! -f /etc/nginx/certs/key.pem) ]];
    then
        # shellcheck disable=SC2164
        cd /etc/nginx/certs
        openssl req -x509 -subj "/CN=$MISP_MISP_HOSTNAME" -nodes -newkey rsa:4096 -keyout key.pem -out cert.pem -days 365
    fi
}

init_mysql(){
    # Test when MySQL is ready....
    # wait for Database come ready
    isDBup () {
        echo "SHOW STATUS" | $MISP_MYSQL_MYSQLCMD 1>/dev/null
        echo $?
    }

    isDBinitDone () {
        # Table attributes has existed since at least v2.1
        echo "DESCRIBE attributes" | $MISP_MYSQL_MYSQLCMD 1>/dev/null
        echo $?
    }

    RETRY=100
    # shellcheck disable=SC2046
    until [ $(isDBup) -eq 0 ] || [ $RETRY -le 0 ] ; do
        echo "Waiting for database to come up"
        sleep 5
        RETRY=$(( RETRY - 1))
    done
    if [ $RETRY -le 0 ]; then
        >&2 echo "Error: Could not connect to Database on $MISP_MYSQL_HOST:$MISP_MYSQL_PORT"
        exit 1
    fi

     # shellcheck disable=SC2046
    if [ $(isDBinitDone) -eq 0 ]; then
        echo "Database has already been initialized"
    else
        echo "Database has not been initialized, importing MySQL scheme..."
        $MISP_MYSQL_MYSQLCMD < /var/www/MISP/INSTALL/MYSQL.sql
    fi
}

sync_files(){
     # shellcheck disable=SC2045
    for DIR in $(ls /var/www/MISP/app/files.dist); do
        rsync -azh --delete "/var/www/MISP/app/files.dist/$DIR" "/var/www/MISP/app/files/"
    done
}

# Ensure SSL certs are where we expect them, for backward comparibility See issue #53
for CERT in cert.pem dhparams.pem key.pem; do
    echo "/etc/nginx/certs/$CERT /etc/ssl/certs/$CERT"
    if [[ ! -f "/etc/nginx/certs/$CERT" && -f "/etc/ssl/certs/$CERT" ]]; then
        WARNING53=true
        cp /etc/ssl/certs/$CERT /etc/nginx/certs/$CERT
    fi
done

# Things we should do when we have the INITIALIZE Env Flag
if [[ "$MISP_ENTRYPOINT_NGINX_INIT" == true ]]; then
    echo "Setup MySQL..." && init_mysql
    echo "Setup MISP files dir..." && init_misp_files
    echo "Ensure SSL certs exist..." && init_ssl
fi

# Things that should ALWAYS happen
echo "Configure Cake | Change Redis host to $MISP_REDIS_HOST ... " && setup_cake_config

# Things we should do if we're configuring MISP via ENV
echo "Configure MISP | Initialize misp base config..." && init_misp_config

echo "Configure MISP | Sync app files..." && sync_files

echo "Configure MISP | Enforce permissions ..."
echo "... chown -R www-data.www-data /var/www/MISP ..." && find /var/www/MISP -not -user www-data -exec chown www-data.www-data {} +
echo "... chmod -R 0750 /var/www/MISP ..." && find /var/www/MISP -perm 550 -type f -exec chmod 0550 {} + && find /var/www/MISP -perm 770 -type d -exec chmod 0770 {} +
echo "... chmod -R g+ws /var/www/MISP/app/tmp ..." && chmod -R g+ws /var/www/MISP/app/tmp
echo "... chmod -R g+ws /var/www/MISP/app/files ..." && chmod -R g+ws /var/www/MISP/app/files
echo "... chmod -R g+ws /var/www/MISP/app/files/scripts/tmp ..." && chmod -R g+ws /var/www/MISP/app/files/scripts/tmp

# Work around https://github.com/MISP/MISP/issues/5608
if [[ ! -f /var/www/MISP/PyMISP/pymisp/data/describeTypes.json ]]; then
    mkdir -p /var/www/MISP/PyMISP/pymisp/data/
    ln -s /usr/local/lib/python3.7/dist-packages/pymisp/data/describeTypes.json /var/www/MISP/PyMISP/pymisp/data/describeTypes.json
fi

if [[ ! -L "/etc/nginx/sites-enabled/misp80" && "$MISP_ENTRYPOINT_NGINX_NOREDIRECT" == true ]]; then
    echo "Configure NGINX | Disabling Port 80 Redirect"
    ln -s /etc/nginx/sites-available/misp80-noredir /etc/nginx/sites-enabled/misp80
elif [[ ! -L "/etc/nginx/sites-enabled/misp80" ]]; then
    echo "Configure NGINX | Enable Port 80 Redirect"
    ln -s /etc/nginx/sites-available/misp80 /etc/nginx/sites-enabled/misp80
else
    echo "Configure NGINX | Port 80 already configured"
fi

if [[ ! -L "/etc/nginx/sites-enabled/misp" && "$MISP_ENTRYPOINT_NGINX_SECURESSL" == true ]]; then
    echo "Configure NGINX | Using Secure SSL"
    ln -s /etc/nginx/sites-available/misp-secure /etc/nginx/sites-enabled/misp
elif [[ ! -L "/etc/nginx/sites-enabled/misp" ]]; then
    echo "Configure NGINX | Using Standard SSL"
    ln -s /etc/nginx/sites-available/misp /etc/nginx/sites-enabled/misp
else
    echo "Configure NGINX | SSL already configured"
fi

if [[ ! "$MISP_ENTRYPOINT_NGINX_SECURESSL" == true && ! -f /etc/nginx/certs/dhparams.pem ]]; then
    echo "Configure NGINX | Building dhparams.pem"
    openssl dhparam -out /etc/nginx/certs/dhparams.pem 2048
fi

if [[ "$MISP_ENTRYPOINT_NGINX_DISABLEIPV6" == true ]]; then
    echo "Configure NGINX | Disabling IPv6"
    sed -i "s/listen \[\:\:\]/\#listen \[\:\:\]/" /etc/nginx/sites-enabled/misp80
    sed -i "s/listen \[\:\:\]/\#listen \[\:\:\]/" /etc/nginx/sites-enabled/misp
fi

if [[ -x /custom-entrypoint.sh ]]; then
    /custom-entrypoint.sh
fi

# delete pid file
[ -f "$MISP_ENTRYPOINT_NGINX_PID_FILE" ] && rm "$MISP_ENTRYPOINT_NGINX_PID_FILE"

if [[ "$WARNING53" == true ]]; then
    echo "WARNING - WARNING - WARNING"
    echo "The SSL certs have moved. You currently have them mounted to /etc/ssl/certs."
    echo "This needs to be changed to /etc/nginx/certs."
    echo "See: https://github.com/coolacid/docker-misp/issues/53"
    echo "WARNING - WARNING - WARNING"
fi

# Start NGINX
nginx -g 'daemon off;'
