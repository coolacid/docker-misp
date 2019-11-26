#!/bin/sh

cat << EOF > /etc/cron.d/misp
00 0 * * * www-data /var/www/MISP/app/Console/cake Server pull "$CRON_USER_ID" >/dev/stdout 2>/dev/stdout
10 0 * * * www-data /var/www/MISP/app/Console/cake Server push "$CRON_USER_ID" >/dev/stdout 2>/dev/stdout
20 0 * * * www-data /var/www/MISP/app/Console/cake Server cacheFeed "$CRON_USER_ID" all >/dev/stdout 2>/dev/stdout
30 0 * * * www-data /var/www/MISP/app/Console/cake Server fetchFeed "$CRON_USER_ID" all >/dev/stdout 2>/dev/stdout

00 1 * * * www-data /var/www/MISP/app/Console/cake Admin updateGalaxies >/dev/stdout 2>/dev/stdout
10 1 * * * www-data /var/www/MISP/app/Console/cake Admin updateTaxonomies >/dev/stdout 2>/dev/stdout
20 1 * * * www-data /var/www/MISP/app/Console/cake Admin updateWarningLists >/dev/stdout 2>/dev/stdout
30 1 * * * www-data /var/www/MISP/app/Console/cake Admin updateNoticeLists >/dev/stdout 2>/dev/stdout
40 1 * * * www-data /var/www/MISP/app/Console/cake Admin updateObjectTemplates >/dev/stdout 2>/dev/stdout

EOF

cron -f
