#!/bin/sh

STORAGE_SIZE=$(df | grep "/media/Ai" | awk '{print $2}')

if [ "$STORAGE_SIZE" -lt "5000000" ]; then
	kill -9 "`pidof nkn-updater.sh`"
	killall -q nknd
	
	nvram set nkn_enable=0
	nvram commit
	/usr/bin/logger -t nknd Storage space is less than 5G, disable NKN node
fi
