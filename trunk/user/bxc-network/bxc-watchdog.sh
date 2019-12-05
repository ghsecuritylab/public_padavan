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
			nice --10 /usr/sbin/bxc-network >/dev/null 2>&1 &
		else
			logger -t bxc-watchdog "Network problem"
		fi
	fi

	curl -I -m 3 -x http://127.0.0.1:8901 http://www.baidu.com
	if [ "$?" != "0" ]; then
		wget -s -q -T 3 www.baidu.com
		if [ "$?" == "0" ]; then
			/usr/bin/logger -t bxc-watchdog "Network task malfunction!"
			while true; do
				cnt2=$((cnt2+1))
				while [ -n "`pidof bxc-worker-legacy`" ] ; do
					killall bxc-worker-legacy
					sleep 1
				done
				nice --10 /usr/sbin/bxc-worker-legacy >/dev/null 2>&1 &
				sleep 3
				curl -I -m 3 -x http://127.0.0.1:8901 http://www.baidu.com
				if [ "$?" == "0" ]; then
					logger -t bxc-watchdog "Restart bxc-worker-legacy($cnt2)"
					break
				fi
			done
		else
			logger -t bxc-watchdog "Network problem!"
		fi
	fi

done
