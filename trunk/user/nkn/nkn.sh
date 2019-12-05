#!/bin/sh

NKN_PASSWD=$(nvram get nkn_wallet_passwd)
NKN_WADDR=$(nvram get nkn_wallet_address)

if [ -e /dev/mmcblk0 ]; then
	NKN_USB_ROOT=$(cat /proc/mounts | grep 'AiCard_NKN' | head -n 1 | awk '{print $2}')
elif [ -e /dev/sda ]; then
	NKN_USB_ROOT=$(cat /proc/mounts | grep 'AiDisk_NKN' | head -n 1 | awk '{print $2}')
else
	NKN_USB_ROOT=$(cat /proc/mounts | grep 'AiCifs_NKN' | head -n 1 | awk '{print $2}')
fi

func_info()
{
	if [ -n "`pidof nknd`" ]; then
		NKN_STATE_LOCAL=$(nknc-info.sh state)
		if [ ! -z "$NKN_STATE_LOCAL" ]; then
			NKN_LATEST_LOG=$(ls -lt "${NKN_USB_ROOT}"/nkn/Log/*.log | head -n 1 | awk '{print $9}')
			if [ ! -z "$NKN_LATEST_LOG" ]; then
				NKN_NAT_WARN=$(tail -10 "$NKN_LATEST_LOG" | grep "Local node has no inbound neighbor" | tail -1 | sed -r 's/'$(echo -e "\033")'\[[0-9;]*m?//g')
				if [ ! -z "$NKN_NAT_WARN" ]; then
					echo "$NKN_NAT_WARN"
				fi
			fi
			echo "$NKN_STATE_LOCAL"
		fi
	else
		echo "NKN node is not running."
	fi
}

func_neighbor()
{
	if [ -n "`pidof nknd`" ]; then
		nknc-info.sh neighbor
	else
		echo "NKN node is not running."
	fi
}

func_wallet()
{
	if [ -f /etc/storage/nkn/wallet.json ]; then
		NKN_WADDR_CUR=$(cat /etc/storage/nkn/wallet.json | jq -r .Address | xargs echo -n)
		if [ "${NKN_WADDR_CUR:0:3}" != "NKN" ]; then
			NKN_WADDR_CUR="Invalid_Wallet_File"
		fi
		nvram set nkn_wallet_address=$NKN_WADDR_CUR
		nvram commit
		echo -n "$NKN_WADDR_CUR"
	fi
}

func_balance()
{
	if [ -n "`pidof nknd`" ]; then
		if [ -z "$1" ]; then
			nknc-info.sh balance "$NKN_WADDR"
		else
			nknc-info.sh balance "$1"
		fi
	else
		echo -n "n/a"
	fi
}

func_transfer()
{
	if [ -n "`pidof nknd`" ]; then
		killall -q nknc
		cd ${NKN_USB_ROOT}/nkn
		NKN_NONCE=$(nknc-info.sh nonce $NKN_WADDR)
		if [ "$NKN_NONCE" != "$(nvram get nkn_nonce)" ]; then
			NKN_TRANS_RESULT=$(./nknc asset --transfer --password "$1" --to "$2" --value "$3" --fee "$4" --nonce "$NKN_NONCE")
			echo "$NKN_TRANS_RESULT" | grep result >/dev/null
			if [ "$?" == "0" ]; then
				nvram set nkn_nonce=$NKN_NONCE
			fi
			echo "$NKN_TRANS_RESULT"
		else
			echo "Pending transaction found, please try again later."
		fi		
	else
		echo "Please start NKN node before transfer."
	fi
}

func_logs()
{
	NKN_LOG_FILE=$(ls -lt "${NKN_USB_ROOT}"/nkn/Log/*_LOG.log | head -n 1 | awk '{print $9}')
	if [ ! -z "${NKN_LOG_FILE}" ]; then
		tail -500 "${NKN_LOG_FILE}" | sed -r 's/'$(echo -e "\033")'\[[0-9;]*m?//g'
	fi
}

func_logs_pre()
{
	NKN_LOG_FILE=$(ls -lt "${NKN_USB_ROOT}"/nkn/Log/*_LOG.log | awk 'NR==2 {print $9}')
	if [ ! -z "${NKN_LOG_FILE}" ]; then
		tail -500 "${NKN_LOG_FILE}" | sed -r 's/'$(echo -e "\033")'\[[0-9;]*m?//g'
	fi
}

func_logs_dump()
{
	NKN_LOG_FILE=$(ls -lt "${NKN_USB_ROOT}"/nkn/Log/*_LOG.log | head -n 1 | awk '{print $9}')
	rm -rf /tmp/nknlog.txt
	if [ ! -z "${NKN_LOG_FILE}" ]; then
		ln -s "${NKN_LOG_FILE}" /tmp/nknlog.txt
	else
		touch /tmp/nknlog.txt
	fi
}


func_checkupdate()
{
	NKN_MD5_LOCAL=$(cat /usr/share/nkn/nkn.md5)

	if [ -f "${NKN_USB_ROOT}/nkn/nkn.tgz" ]; then
		NKN_MD5_LOCAL=$(md5sum "${NKN_USB_ROOT}/nkn/nkn.tgz" | awk '{print $1}')
	fi

	NKN_MD5_REMOTE=$(curl --cacert /etc/ssl/certs/ca-certificates.crt --retry 3 --silent -L https://nkn.4h8h.top/padavan/nkn.md5)

	if [ "$(echo ${NKN_MD5_REMOTE} | wc -m)" != "33" ]; then
		if [ -f ${NKN_USB_ROOT}/nkn/nkn.tgz ]; then
			/usr/bin/logger -t nknd "Update failed, load NKN node from MMC/USB"
			tar -xzvf "${NKN_USB_ROOT}/nkn/nkn.tgz" -C "${NKN_USB_ROOT}/nkn"
		elif [ -f /usr/share/nkn/nkn.tgz ]; then
			/usr/bin/logger -t nknd "Update failed, load NKN node from ROM"
			tar -xzvf /usr/share/nkn/nkn.tgz -C "${NKN_USB_ROOT}/nkn"
		else
			nvram set nkn_enable=0
			nvram commit
			/usr/bin/logger -t nknd "Update failed, disable NKN node"
			exit 1
		fi
		return
	fi

	if [ "${NKN_MD5_LOCAL}" = "${NKN_MD5_REMOTE}" ]; then
		if [ -f "${NKN_USB_ROOT}/nkn/nkn.tgz" ]; then
			/usr/bin/logger -t nknd "Local NKN node(MMC/USB) is up-to-date, continue"
			tar -xzvf "${NKN_USB_ROOT}/nkn/nkn.tgz" -C "${NKN_USB_ROOT}/nkn"
		else
			/usr/bin/logger -t nknd "Local NKN node(ROM) is up-to-date, continue"
			tar -xzvf /usr/share/nkn/nkn.tgz -C "${NKN_USB_ROOT}/nkn"
		fi
	else
		/usr/bin/logger -t nknd New version of NKN node has been found, updating...
		while [ "${NKN_MD5_DOWNLOAD}" != "${NKN_MD5_REMOTE}" ]; do
			curl --cacert /etc/ssl/certs/ca-certificates.crt --retry 10 --silent -L --output ${NKN_USB_ROOT}/nkn/nkn.tgz https://nkn.4h8h.top/padavan/nkn.tgz
			NKN_MD5_DOWNLOAD=$(md5sum ${NKN_USB_ROOT}/nkn/nkn.tgz | awk '{print $1}')
			/usr/bin/logger -t nknd New version of NKN node has been downloaded
		done
		tar -xzvf "${NKN_USB_ROOT}/nkn/nkn.tgz" -C "${NKN_USB_ROOT}/nkn"

		if [ -f "${NKN_USB_ROOT}/nkn/post_nknd_upgrade.sh" ]; then
			/usr/bin/logger -t nknd "Run post_nknd_upgrade.sh"
			${NKN_USB_ROOT}/nkn/post_nknd_upgrade.sh
		fi
	fi
}

func_cleanlogs()
{
	NKN_LOG_SIZE=$(du "${NKN_USB_ROOT}/nkn/Log" | tail -1 | awk '{print $1}')

	while [ "${NKN_LOG_SIZE}" -gt "50000" ]; do
		NKN_OLDLOG_FILE=$(ls -lrt "${NKN_USB_ROOT}"/nkn/Log/*.log | head -n 1 | awk '{print $9}')
		/usr/bin/logger -t nknd "Purge NKN node log - "$(basename ${NKN_OLDLOG_FILE})
		rm -rf "${NKN_OLDLOG_FILE}"
		NKN_LOG_SIZE=$(du "${NKN_USB_ROOT}/nkn/Log" | tail -1 | awk '{print $1}')
	done
}

func_resetChainOnError()
{
	NKN_LATEST_LOG=$(ls -lt "${NKN_USB_ROOT}"/nkn/Log/*.log | head -n 1 | awk '{print $9}')

	if [ ! -z "${NKN_LATEST_LOG}" ]; then
		NKN_PB_ERROR=$(tail -100 "${NKN_LATEST_LOG}" | grep "error to persist block")
		if [ ! -z "${NKN_PB_ERROR}" ]; then
			/usr/bin/logger -t nknd "Found persist block error in logs, reset Chain directory"
			func_resetChain
		fi
	fi
}

func_reset()
{
	NKN_ENABLED=$(nvram get nkn_enable)
	if [ "$NKN_ENABLED" = "1" ]; then
		nvram set nkn_starting=1
		func_stop
	fi

	func_resetChain

	if [ "$NKN_ENABLED" = "1" ]; then
		func_start
	fi
}

func_resetChain()
{
	rm -rf "${NKN_USB_ROOT}/nkn/Chain"
	rm -rf "${NKN_USB_ROOT}/nkn/ChainDB"
	/usr/bin/logger -t nknd "ChainDB directory has been reset."
}

func_mount()
{
	modprobe des_generic
	modprobe cifs CIFSMaxBufSize=64512
	mkdir -p /media/AiCifs_NKN
	mount -t cifs "$1" /media/AiCifs_NKN -o username="$2",password="$3"
}

func_umount()
{
	umount /media/AiCifs_NKN
}

func_initMMC()
{
ejmmc

fdisk -u /dev/mmcblk0 <<EOF
d
1
d
2
d
3
d
4
n
p
1

+256M
n
p
2


t
1
82
p
w
EOF

mdev -s
ejmmc

mkswap /dev/mmcblk0p1
mkfs.ext4 -m 0 -L AiCard_NKN /dev/mmcblk0p2

mdev -s
}

func_initUSB()
{
ejusb

fdisk -u /dev/sda <<EOF
d
1
d
2
d
3
d
4
n
p
1

+256M
n
p
2


t
1
82
p
w
EOF

mdev -s
ejusb

mkswap /dev/sda1
mkfs.ext4 -m 0 -L AiDisk_NKN /dev/sda2

mdev -s
}

func_format()
{
	NKN_ENABLED=$(nvram get nkn_enable)
	if [ "$NKN_ENABLED" = "1" ]; then
		nvram set nkn_starting=1
		func_stop
	fi

	func_format_nostart

	if [ "$NKN_ENABLED" = "1" ]; then
		func_start
	fi
}

func_format_nostart()
{
	NKN_USB_ROOT=""
	if [ -e /dev/mmcblk0 ]; then
		SwapTotal="0"
		while [ -z "$NKN_USB_ROOT" ] || [ "$SwapTotal" -lt "200000" ]; do
			/usr/bin/logger -t nknd Initializing MMC device...
			func_initMMC
			NKN_USB_ROOT=$(cat /proc/mounts | grep 'AiCard_NKN' | head -n 1 | awk '{print $2}')
			SwapTotal=$(cat /proc/meminfo | grep SwapTotal| awk '{print $2}')
		done
	elif [ -e /dev/sda ]; then
		while [ -z "$NKN_USB_ROOT" ] || [ "$SwapTotal" -lt "200000" ]; do
			/usr/bin/logger -t nknd Initializing USB storage device...
			func_initUSB
			NKN_USB_ROOT=$(cat /proc/mounts | grep 'AiDisk_NKN' | head -n 1 | awk '{print $2}')
			SwapTotal=$(cat /proc/meminfo | grep SwapTotal| awk '{print $2}')
		done
	fi
}

func_gen_wallet()
{
RANDOM_PASSWD=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | head -c 8)
cd ${NKN_USB_ROOT}/nkn
rm -rf ./wallet.json
./nknc wallet --create <<EOF
${RANDOM_PASSWD}
${RANDOM_PASSWD}
EOF

mkdir -p /etc/storage/nkn
cp -f ./wallet.json /etc/storage/nkn/wallet.json
/sbin/mtd_storage.sh save

nvram set nkn_wallet_passwd=${RANDOM_PASSWD}
func_wallet

NKN_PASSWD=$(nvram get nkn_wallet_passwd)
NKN_WADDR=$(nvram get nkn_wallet_address)
}

func_start()
{
	nvram set nkn_starting=1

	NKN_BENEFICIARY_ADDR=$(nvram get nkn_beneficiary_address)

	if [ ! -f /etc/storage/nkn/wallet.json ] && [ -z "$NKN_BENEFICIARY_ADDR" ]; then
		nvram set nkn_enable=0
		nvram commit
		/usr/bin/logger -t nknd NKN wallet not found, disable NKN node
		exit 1
	fi

	if [ -z "${NKN_USB_ROOT}" ]; then
		UPTIME=$(cat /proc/uptime | awk '{printf "%0.f", $1}')
		if [ "$UPTIME" -lt "60" ]; then
			sleep 60
		fi

		mdev -s
		if [ -e /dev/mmcblk0 ]; then
			NKN_USB_ROOT=$(cat /proc/mounts | grep 'AiCard_NKN' | head -n 1 | awk '{print $2}')
		elif [ -e /dev/sda ]; then
			NKN_USB_ROOT=$(cat /proc/mounts | grep 'AiDisk_NKN' | head -n 1 | awk '{print $2}')
		else
			NKN_USB_ROOT=$(cat /proc/mounts | grep 'AiCifs_NKN' | head -n 1 | awk '{print $2}')
		fi
	fi

	if [ -z "${NKN_USB_ROOT}" ]; then
		func_format_nostart
	fi

	if [ -z "${NKN_USB_ROOT}" ]; then
		nvram set nkn_enable=0
		nvram commit
		/usr/bin/logger -t nknd Storage device not attached, disable NKN node
		exit 1
	fi

	MemTotal=$(cat /proc/meminfo | grep MemTotal | awk '{print $2}')
	SwapTotal=$(cat /proc/meminfo | grep SwapTotal| awk '{print $2}')

	if [ "$MemTotal" -lt "200000" ]; then
		if [ "$SwapTotal" -lt "200000" ]; then
			nvram set nkn_enable=0
			nvram commit
			/usr/bin/logger -t nknd Swap space less than 200M, disable NKN node
			exit 1
		fi
	fi

	if [ -d "${NKN_USB_ROOT}/nkn/Log" ]; then
		func_cleanlogs
	else
		mkdir -p "${NKN_USB_ROOT}/nkn/Log"
	fi

	if [ -z "$1" ]; then
		func_checkupdate
		/usr/bin/nkn-updater.sh >/dev/null 2>&1 &

		nvram set nkn_restart_cnt=0

		if [ "$NKN_BENEFICIARY_ADDR" != "" ]; then
			/usr/bin/logger -t nknd "Beneficiary Address: ${NKN_BENEFICIARY_ADDR}"
			sed -i -e '2i\  "BeneficiaryAddr": "'${NKN_BENEFICIARY_ADDR}'",' "${NKN_USB_ROOT}/nkn/config.json"

			if [ ! -f /etc/storage/nkn/wallet.json ]; then
				func_gen_wallet
				/usr/bin/logger -t nknd "NKN wallet auto-generated: ${NKN_WADDR}"
			fi
		fi

		nvram set nkn_nonce=x
	else
		NKN_RESTART_CNT=$(nvram get nkn_restart_cnt)
		/usr/bin/logger -t nknd "Restart by watchdog($NKN_RESTART_CNT)"
		NKN_RESTART_CNT=$((NKN_RESTART_CNT+1))
		nvram set nkn_restart_cnt=$NKN_RESTART_CNT
	fi

	func_resetChainOnError

	cp -f /etc/storage/nkn/wallet.json "${NKN_USB_ROOT}/nkn/wallet.json"

	/usr/bin/logger -t nknd Start NKN node
	export "PATH=$PATH:${NKN_USB_ROOT}/nkn"
	cd "${NKN_USB_ROOT}/nkn"
	echo $NKN_PASSWD > /etc/storage/nkn/wallet.pswd
	nknd </etc/storage/nkn/wallet.pswd >/dev/null 2>&1 &

	if [ -f "${NKN_USB_ROOT}/nkn/post_nknd_start.sh" ]; then
		/usr/bin/logger -t nknd "Run post_nknd_start.sh"
		${NKN_USB_ROOT}/nkn/post_nknd_start.sh
	fi

	nvram set nkn_starting=0
}

func_stop()
{
	if [ -z "$1" ]; then
		/usr/bin/logger -t nknd Stop NKN updater
		kill -9 "`pidof nkn-updater.sh`"
	fi

	if [ -f "${NKN_USB_ROOT}/nkn/pre_nknd_stop.sh" ]; then
		/usr/bin/logger -t nknd "Run pre_nknd_stop.sh"
		${NKN_USB_ROOT}/nkn/pre_nknd_stop.sh
	fi

	/usr/bin/logger -t nknd Stop NKN node
	killall -q nknd
}

func_updatefw()
{
	iptables -I INPUT -p tcp --match multiport --dports 30001:30003 -j ACCEPT
}

case "$1" in
start)
	func_start "$2"
	;;
stop)
	func_stop "$2"
	;;
info)
	func_info
	;;
neighbor)
	func_neighbor
	;;
wallet)
	func_wallet
	;;
balance)
	func_balance "$2"
	;;
transfer)
	func_transfer "$2" "$3" "$4" "$5"
	;;
cleanlogs)
	func_cleanlogs
	;;
reset)
	func_reset
	;;
format)
	func_format
	;;
logs)
	func_logs
	;;
logs_pre)
	func_logs_pre
	;;
logs_dump)
	func_logs_dump
	;;
updatefw)
	func_updatefw
	;;
mount)
	func_mount "$2" "$3" "$4"
	;;
umount)
	func_umount
	;;
*)
	echo "Usage: $0 {start|stop|info|neighbor|wallet|balance|transfer|cleanlogs|reset|logs}"
	exit 1
	;;
esac

exit 0
