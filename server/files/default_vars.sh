#!/bin/sh

#
# This file contains all valid environments variables and their default value, which is in entrypoint used.
# The structure of the environment variables are:
# MISP_<Component>_<SectionName>_<SettingName>
# This file will used in the entrypoint.sh.
#


#### LEGACY ENV
#
#    This area is added until 2022, to support the legacy variants of environment variables.
#
# For the following environment variable a extra check must be done, because it will be set always.
# https://linuxize.com/post/how-to-check-if-string-contains-substring-in-bash/
# echo "$1" | grep -q "$2"
# shellcheck disable=SC2039
[ $(echo "$HOSTNAME"|grep -q "http") ] || MISP_MISP_BASEURL=${HOSTNAME}
MISP_REDIS_HOST=${REDIS_FQDN}
MISP_ENTRYPOINT_NGINX_INIT=${INIT}
MISP_CRON_USER_ID=${CRON_USER_ID}
MISP_CRON_SYNCSERVERS=${SYNCSERVERS}
MISP_MYSQL_HOST=${MYSQL_HOST}
MISP_MYSQL_USER=${MYSQL_USER}
MISP_MYSQL_PASSWORD=${MYSQL_PASSWORD}
MISP_MYSQL_DB=${MYSQL_DATABASE}
MISP_ENTRYPOINT_NGINX_NOREDIRECT=${NOREDIR}
MISP_ENTRYPOINT_NGINX_DISABLEIPV6=${DISIPV6}
MISP_ENTRYPOINT_NGINX_SECURESSL=${SECURESSL}
MISP_MISPMODULES_FQDN=${MISP_MODULES_FQDN}
#### LEGACY END

# Entrypoint NGINX
## Set PID file:
MISP_ENTRYPOINT_NGINX_PID_FILE=${MISP_ENTRYPOINT_NGINX_PID_FILE:-"/entrypoint_apache.install"}
## Set Hostname for selfsigned certificate
# shellcheck disable=SC2039
MISP_ENTRYPOINT_NGINX_HOSTNAME=${MISP_ENTRYPOINT_NGINX_HOSTNAME:-"$HOSTNAME"}
## Do not redirect port 80:
MISP_ENTRYPOINT_NGINX_NOREDIRECT=${MISP_ENTRYPOINT_NGINX_NOREDIRECT:-"true"}
## Disable IPV6 in NGINX:
MISP_ENTRYPOINT_NGINX_DISABLEIPV6=${MISP_ENTRYPOINT_NGINX_DISABLEIPV6:-"true"}
## Enable higher security SSL in NIGNX:
MISP_ENTRYPOINT_NGINX_SECURESSL=${MISP_ENTRYPOINT_NGINX_SECURESSL:-"true"}
## Deactivate intitialization if it is not explicit set:
MISP_ENTRYPOINT_NGINX_INIT=${MISP_ENTRYPOINT_NGINX_INIT:-"false"}


# Entrypoint Workers
## Set Worker Path
ENTRYPOINT_WORKERS_BIN_FILE=${ENTRYPOINT_WORKERS_BIN_FILE:-"/var/www/MISP/app/Console/worker/start.sh"}

# Entrypoint FPM
## Set memory_limit in MB:
ENTRYPOINT_FPM_PHP_MEMORY_LIMIT=${ENTRYPOINT_FPM_PHP_MEMORY_LIMIT:-"2048M"}
## Set max_execution_time in seconds:
ENTRYPOINT_FPM_PHP_MAX_EXECUTION_TIME=${ENTRYPOINT_FPM_PHP_MAX_EXECUTION_TIME:-"300"}
## Set upload_max_filesize in MB:
ENTRYPOINT_FPM_PHP_UPLOAD_MAX_FILESIZE=${ENTRYPOINT_FPM_PHP_UPLOAD_MAX_FILESIZE:-"50M"}
## Set post_max_size in MB:
ENTRYPOINT_FPM_PHP_POST_MAX_SIZE=${ENTRYPOINT_FPM_PHP_POST_MAX_SIZE:-"50M"}

# Cake
## Set Cake File Path
MISP_CAKE_FILE=${MISP_CAKE_FILE:-"/var/www/MISP/app/Console/cake"}

# Cron
MISP_CRON_USER_ID=${MISP_CRON_USER_ID:-"1"}
MISP_CRON_SYNCSERVERS=${MISP_CRON_SYNCSERVERS:-""}

# Redis
## Set Redis Server Host:
MISP_REDIS_HOST=${MISP_REDIS_HOST:-"redis"}
## Set Redis Server Port:
MISP_REDIS_PORT=${MISP_REDIS_PORT:-"6379"}
## Set Redis Database which should be used for MISP:
MISP_REDIS_DB=${MISP_REDIS_DB:-"0"}
## Set Redis Password if authentication is activated:
MISP_REDIS_PASSWORD=${MISP_REDIS_PASSWORD:-""}

# MISP-Modules
## Set MISP-Module Host:
MISP_MISPMODULES_HOST=${MISP_MISPMODULES_HOST:-"misp-modules"}
## Set MISP-Module Port:
MISP_MISPMODULES_PORT=${MISP_MISPMODULES_PORT:-"6666"}
## Set MISP-Module FQDN:
MISP_MISPMODULES_FQDN=${MISP_MISPMODULES_FQDN:-"http://${MISP_MISPMODULES_HOST}:${MISP_MISPMODULES_PORT}"}

# MySQL
## Set MySQL Host:
MISP_MYSQL_HOST=${MISP_MYSQL_HOST:-"db"}
## Set MySQL Port:
MISP_MYSQL_PORT=${MISP_MYSQL_PORT:-"3306"}
## Set MySQL username:
MISP_MYSQL_USER=${MISP_MYSQL_USER:-"dbuser"}
## Set MySQL user password:
MISP_MYSQL_PASSWORD=${MISP_MYSQL_PASSWORD:-"ChangeMe!"}
## Set MySQL database:
MISP_MYSQL_DB=${MISP_MYSQL_DB:-"misp"}
## Set Default MySQL CMD:
MISP_MYSQL_MYSQLCMD=${MISP_MYSQL_MYSQLCMD:-"mysql -u $MISP_MYSQL_USER -p$MISP_MYSQL_PASSWORD -P $MISP_MYSQL_PORT -h $MISP_MYSQL_HOST -r -N  $MISP_MYSQL_DB"}


# MISP Settings
## Set MISP App Config Path:
MISP_MISP_APP_CONFIG_PATH=${MISP_MISP_APP_CONFIG_PATH:-"/var/www/MISP/app/Config"}
## Set BaseURL
MISP_MISP_BASEURL=${MISP_MISP_BASEURL:-"$ENTRYPOINT_NGINX_HOSTNAME"}
## Activate MISP Instance on start:
MISP_MISP_Base_LIVE=${MISP_MISP_Base_LIVE:-"true"}
## Activate CustomAuth_Enable setting:
MISP_MISP_PLUGIN_CUSTOMAUTH_ENABLE=${MISP_MISP_PLUGIN_CUSTOMAUTH_ENABLE:-"true"}

