#!/bin/sh

MACADDR=$(cat /sys/class/net/eth2.2/address)

BXC_SSL_DIR="/etc/storage/bcloud"
BXC_SSL_RES="/etc/storage/bcloud/curl.res"
BXC_SSL_KEY="/etc/storage/bcloud/client.key"
BXC_SSL_CRT="/etc/storage/bcloud/client.crt"
BXC_SSL_CA="/etc/storage/bcloud/ca.crt"
BXC_BOUND_URL="https://console.bonuscloud.io/api/web/devices/bind/"
BXC_REPORT_URL="https://bxcvenus.com/idb/dev"
BXC_VER_LOC="/www/bonuscloud.asp"
BXC_INFO_LOC="/etc/storage/bcloud/info"
BXC_JSON="bxc-json.sh"

EMAIL_LOC="/etc/storage/bcloud/email"
EMAIL_OLD=$(cat $EMAIL_LOC)
EMAIL_NEW=$(nvram get bxc_email)
BCODE_LOC="/etc/storage/bcloud/bcode"
BCODE_OLD=$(cat $BCODE_LOC)
BCODE_NEW=$(nvram get bxc_bcode)

func_bound_bcode()
{
	nvram set bxc_bounded=0
	mkdir -p $BXC_SSL_DIR
	rm -rf $BXC_SSL_RES $BXC_SSL_CA $BXC_SSL_CRT $BXC_SSL_KEY $BXC_INFO_LOC $EMAIL_LOC $BCODE_LOC

	curl -k -m 10 -H "Content-Type: application/json" -d "{\"email\":\"$EMAIL_NEW\", \"bcode\":\"$BCODE_NEW\", \"mac_address\":\"$MACADDR\"}" -w "\nstatus_code:"%{http_code}"\n" $BXC_BOUND_URL > $BXC_SSL_RES
	bcode_res=$(grep status_code $BXC_SSL_RES | cut -d : -f 2)
	if [ "$bcode_res" = "200" ]; then
		echo -e `cat $BXC_SSL_RES | $BXC_JSON | egrep "\"Cert\",\"key\"" | awk -F\" '{print $6}' | sed 's/"//g'` | base64 -d > $BXC_SSL_KEY
		echo -e `cat $BXC_SSL_RES | $BXC_JSON | egrep "\"Cert\",\"cert\"" | awk -F\" '{print $6}' | sed 's/"//g'` | base64 -d > $BXC_SSL_CRT
		echo -e `cat $BXC_SSL_RES | $BXC_JSON | egrep "\"Cert\",\"ca\"" | awk -F\" '{print $6}' | sed 's/"//g'` | base64 -d > $BXC_SSL_CA
		echo $EMAIL_NEW > $EMAIL_LOC
		echo $BCODE_NEW > $BCODE_LOC
		nvram set bxc_bounded=1
		/usr/bin/logger -t bxc-network Bound device OK
	else
		nvram set bxc_bounded=0
		bcode_failed_res=$(head -n 1  $BXC_SSL_RES | $BXC_JSON | egrep '\["details"\]' | cut -d \" -f 4)
		/usr/bin/logger -t bxc-network "Failed to bound device - $bcode_failed_res"
	fi

	nvram commit
	/sbin/mtd_storage.sh save
}

func_info_report()
{
	version=$(grep BXCVER $BXC_VER_LOC | cut -d \> -f 3 | cut -d \< -f 1)
	cpu_info=$(cat /proc/cpuinfo | grep -e "^processor" | wc -l)
	mem_info=$(cat /proc/meminfo | grep "MemTotal" | awk -F: '{print $2}'| sed 's/ //g')
	hw_arch=$(uname -m)

	info_cur="${version}#${hw_arch}#${cpu_info}#${mem_info}"
	echo "INFO_CUR: $info_cur"

	info_old=$(cat $BXC_INFO_LOC)
	echo "INFO_OLD: $info_old"

	if [ "$info_cur" != "$info_old" ];then
		/usr/bin/logger -t bxc-node "node info changed: \"$info_old\" --> \"$info_cur\", report info..."
		echo $info_cur > $BXC_INFO_LOC
		status_code=`curl -m 10 -k --cacert $BXC_SSL_CA --cert $BXC_SSL_CRT --key $BXC_SSL_KEY -H "Content-Type: application/json" -d "{\"mac\":\"$MACADDR\", \"info\":\"$info_cur\"}" -X PUT -w "\nstatus_code:"%{http_code}"\n" "$BXC_REPORT_URL/$BCODE_NEW" | grep "status_code" | awk -F: '{print $2}'`
		if [ $status_code -eq 200 ];then
			/usr/bin/logger -t bxc-node "node info reported success"
		else
			/usr/bin/logger -t bxc-node "node info reported failed($status_code)"
			echo $info_old > $BXC_INFO_LOC
		fi
		/sbin/mtd_storage.sh save
	else
		/usr/bin/logger -t bxc-node  "node info has not changed: $info_cur"
	fi
}

func_start()
{
	if [ "$BCODE_NEW" != "$BCODE_OLD" ]; then
		func_bound_bcode
	fi

	if [ "`nvram get bxc_bounded`" = "0" ]; then
		nvram set bxc_enable=0
		nvram commit
		/usr/bin/logger -t bxc-network Device has not bounded, disable BonusCloud-Node
		exit 1
	fi

	echo 0 > /proc/sys/net/ipv6/conf/all/disable_ipv6

	if [ ! -d /dev/shm ]; then
		mkdir -v /dev/shm
		mount -vt tmpfs none /dev/shm
		chmod -R 777 /dev/shm/
	fi

	/usr/bin/logger -t bxc-network Start bxc-network
	/usr/sbin/bxc-network >/dev/null 2>&1 &

	/usr/bin/logger -t bxc-worker Start bxc-worker
	/usr/sbin/bxc-worker >/dev/null 2>&1 &

	/usr/bin/logger -t bxc-watchdog Start bxc-watchdog
	/usr/bin/bxc-watchdog.sh >/dev/null 2>&1 &

	func_info_report
}

func_stop()
{
	/usr/bin/logger -t bxc-watchdog Stop bxc-watchdog
	kill -9 "`pidof bxc-watchdog.sh`"

	/usr/bin/logger -t bxc-worker Stop bxc-worker
	killall -q bxc-worker
	killall -q bxc-worker

	/usr/bin/logger -t bxc-network Stop bxc-network
	killall -q bxc-network
}

func_updatefw()
{
	ip6tables -I INPUT -p tcp --dport 8901 -j ACCEPT -i tun0
	ip6tables -I INPUT -p icmpv6 -j ACCEPT -i tun0 
	ip6tables -I INPUT -p udp -j ACCEPT -i tun0 
	ip6tables -I INPUT -p udp -j ACCEPT -i lo
	iptables -I INPUT -p tcp --match multiport --sports 80,443,8080 -j ACCEPT
}

case "$1" in
start)
	func_start
	;;
stop)
	func_stop
	;;
updatefw)
	func_updatefw
	;;
*)
	echo "Usage: $0 {start|stop|updatefw}"
	exit 1
	;;
esac

exit 0
