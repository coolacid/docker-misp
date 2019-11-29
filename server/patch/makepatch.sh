#!/bin/bash
[ -f composer.json ] && rm composer.json
wget https://raw.githubusercontent.com/MISP/MISP/v2.4.118/app/composer.json
diff -u composer.json composer.new > composer.patch