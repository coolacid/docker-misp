#!/bin/bash

#check if .env file has correct SERVER_NAME
server_name=`cat .env | grep SERVER_NAME | awk -F '=' '{print $2}'`
if [[ $server_name =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
	main_interface=`ip route | grep default | awk -F 'dev ' '{print $2}' | awk -F ' ' '{print $1}'`;
	server_main_ip=`ip address show $main_interface | grep "scope global $main_interface" | awk '{print $2}' | awk -F '/' '{print $1}'` 
	if [ "$server_main_ip" != "$server_name" ] && [ "$server_main_ip" != "" ]; then
		echo "changing SERVER_NAME variable..."
		sed -i "s/SERVER_NAME=$server_name/SERVER_NAME=$server_main_ip/" .env
	fi
fi
if [ "$server_name" == "" ]; then
	main_interface=`ip route | grep default | awk -F 'dev ' '{print $2}' | awk -F ' ' '{print $1}'`;
	server_main_ip=`ip address show $main_interface | grep "scope global $main_interface" | awk '{print $2}' | awk -F '/' '{print $1}'`
	echo "setting SERVER_NAME variable..."
	sed -i "s/SERVER_NAME=/SERVER_NAME=$server_main_ip/" .env
fi

#checking if server listens on 25 tcp port
status_25_port=`ss -ntpl | grep 25 | grep -v docker |wc -l`
if [ $status_25_port -gt 0 ]; then
	echo "server listens on 25 port"
	echo "	stopping/disabling postfix"
	systemctl stop postfix && systemctl disable postfix.service
	#checking one more time 25 tcp port status
	status_25_port=`ss -ntpl | grep 25 | grep -v docker | wc -l`
	if [ $status_25_port -gt 0 ]; then
		echo "	server still listens on 25 port, check manually"
		exit
	fi
fi

docker-compose -f docker-compose.yml up -d
