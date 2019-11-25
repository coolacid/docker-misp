#!/bin/bash


echo "Seriously, don't use this"
openssl dhparam -out dhparams.pem 2048
openssl req -x509 -subj '/CN=localhost' -nodes -newkey rsa:4096 -keyout key.pem -out cert.pem -days 365
cp cert.pem chain.pem
