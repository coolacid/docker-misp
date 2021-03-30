#!/bin/bash

# Include default vars file:
# shellcheck disable=SC1091
source "/default_vars.sh"

# start supervisord
/usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
