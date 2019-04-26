#!/bin/sh

cnt=0
cnt2=0
while true; do
	sleep 300
	BXC_GATEWAY="fdff:$(ifconfig tun0 | grep fdff | cut -d : -f 3,4,5,6,7,8):1"
	ping6 -c 3 $BXC_GATEWAY
	if [ "$?" != "0" ]; then
		cnt=$((cnt+1))
		/usr/bin/logger -t bxc-watchdog "Lost connection($cnt)!"
		wget -s -q -T 3 www.baidu.com
		if [ "$?" == "0" ]; then
			logger -t bxc-watchdog "Restart bxc-network"
			while [ -n "`pidof bxc-network`" ] ; do
				kill -9 "`pidof bxc-network`"
				sleep 3
			done
			/usr/sbin/bxc-network >/dev/null 2>&1 &
		else
			logger -t bxc-watchdog "Network problem"
		fi
	fi

	curl -I -m 3 -x http://127.0.0.1:8901 http://www.baidu.com
	if [ "$?" != "0" ]; then
		cnt2=$((cnt2+1))
		/usr/bin/logger -t bxc-watchdog "Network task malfunction($cnt2)!"
		wget -s -q -T 3 www.baidu.com
		if [ "$?" == "0" ]; then
			logger -t bxc-watchdog "Restart bxc-worker"
			while [ -n "`pidof bxc-worker`" ] ; do
				killall -q bxc-worker
				sleep 3
			done
			/usr/sbin/bxc-worker >/dev/null 2>&1 &
		else
			logger -t bxc-watchdog "Network problem"
		fi
	fi

done
