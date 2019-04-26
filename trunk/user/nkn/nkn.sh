#!/bin/sh

NKN_PASSWD=$(nvram get nkn_wallet_passwd)
NKN_WADDR=$(nvram get nkn_wallet_address)

if [ -e /dev/mmcblk0 ]; then
	NKN_USB_ROOT=$(cat /proc/mounts | grep 'AiCard_NKN' | head -n 1 | awk '{print $2}')
else
	NKN_USB_ROOT=$(cat /proc/mounts | grep 'dev.*.media' | head -n 1 | awk '{print $2}')
fi

func_info()
{
	if [ -n "`pidof nknd`" ]; then
		killall -q nknc
		cd ${NKN_USB_ROOT}/nkn
		NKN_STATE_LOCAL=$(./nknc info -s)
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
		killall -q nknc
		cd ${NKN_USB_ROOT}/nkn
		echo -e "RemoteAddress\t\tHeight\t\tRTT\tSyncState"
		./nknc info --neighbor | awk -F : '
			/addr/ { gsub("//","", $3); printf("%s\t\t",$3) }
			/height/ { gsub(" ","", $2);gsub(",","", $2); printf("%s\t\t",$2) }
			/roundTripTime/ { gsub(" ","", $2);gsub(",","", $2); printf("%s\t",$2) }
			/syncState/ { gsub(" ","", $2);gsub(",","", $2);gsub("\"","", $2); printf("%s\n",$2) }
			'
	else
		echo "NKN node is not running."
	fi
}

func_wallet()
{
	if [ -f /etc/storage/nkn/wallet.dat ]; then
		NKN_WADDR_CUR=$(grep -o 'Address":".*ProgramHash' /etc/storage/nkn/wallet.dat | cut -d \" -f 3 | xargs echo -n)
		if [ "${NKN_WADDR_CUR:0:3}" != "NKN" ] && [ -f "${NKN_USB_ROOT}/nkn/nknc" ] && [ ! -z "$NKN_PASSWD" ]; then
			killall -q nknc
			cd ${NKN_USB_ROOT}/nkn
			NKN_WADDR_CUR=$(./nknc wallet -l account -n /etc/storage/nkn/wallet.dat -p "$NKN_PASSWD" | tail -1 | awk '{print $1}' | xargs echo -n)
			if [ "${NKN_WADDR_CUR:0:3}" == "NKN" ] && [ "$NKN_WADDR_CUR" != "$NKN_WADDR" ]; then
				nvram set nkn_wallet_address=$NKN_WADDR_CUR
				nvram commit
			elif [ "${NKN_WADDR_CUR:0:1}" != "N" ]; then
				NKN_WADDR_CUR="Incorrect wallet or password"
			fi
		fi
		echo -n "$NKN_WADDR_CUR"
	fi
}

func_balance()
{
	if [ -n "`pidof nknd`" ]; then
		killall -q nknc
		cd ${NKN_USB_ROOT}/nkn
		if [ -z "$1" ]; then
			./nknc info --balance "$NKN_WADDR" | grep amount | cut -d \" -f 4 | xargs echo -n
		else
			./nknc info --balance "$1" | grep amount | cut -d \" -f 4 | xargs echo -n
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
		NKN_NONCE=$(./nknc info --nonce $NKN_WADDR | grep nonce | awk '{print $2}')
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
	NKN_LOG_FILE=$(ls -lt "${NKN_USB_ROOT}"/nkn/Log/*.log | head -n 1 | awk '{print $9}')
	if [ ! -z "${NKN_LOG_FILE}" ]; then
		tail -100 "${NKN_LOG_FILE}" | sed -r 's/'$(echo -e "\033")'\[[0-9;]*m?//g'
	fi
}

func_checkupdate()
{
	NKN_MD5_LOCAL=$(cat /usr/share/nkn/nkn.md5)

	if [ -f "${NKN_USB_ROOT}/nkn/nkn.tgz" ]; then
		NKN_MD5_LOCAL=$(md5sum "${NKN_USB_ROOT}/nkn/nkn.tgz" | awk '{print $1}')
	fi

	NKN_MD5_REMOTE=$(curl --cacert /etc/ssl/certs/ca-certificates.crt --retry 3 --silent -L https://github.com/bettermanbao/nkn/releases/download/latest/nkn.md5)

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
			curl --cacert /etc/ssl/certs/ca-certificates.crt --retry 10 --silent -L --output ${NKN_USB_ROOT}/nkn/nkn.tgz https://github.com/bettermanbao/nkn/releases/download/latest/nkn.tgz
			NKN_MD5_DOWNLOAD=$(md5sum ${NKN_USB_ROOT}/nkn/nkn.tgz | awk '{print $1}')
			/usr/bin/logger -t nknd New version of NKN node has been downloaded
		done
		tar -xzvf "${NKN_USB_ROOT}/nkn/nkn.tgz" -C "${NKN_USB_ROOT}/nkn"
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

func_resetChain()
{
	rm -rf "${NKN_USB_ROOT}/nkn/Chain"
	rm -rf "${NKN_USB_ROOT}/nkn/ChainDB"
	echo "ChainDB directory has been reset."
}

func_mount()
{
	modprobe des_generic
	modprobe cifs CIFSMaxBufSize=64512
	mkdir -p /media/dev/media/cifs
	mount -t cifs "$1" /media/dev/media/cifs -o username="$2",password="$3"
}

func_umount()
{
	umount /media/dev/media/cifs
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

ejmmc
mkswap /dev/mmcblk0p1

ejmmc
mkfs.ext4 -m 0 -L AiCard_NKN /dev/mmcblk0p2

mdev -s
}

func_start()
{
	nvram set nkn_starting=1

	if [ ! -f /etc/storage/nkn/wallet.dat ]; then
		nvram set nkn_enable=0
		nvram commit
		/usr/bin/logger -t nknd NKN wallet not found, disable NKN node
		exit 1
	fi


	if [ -e /dev/mmcblk0 ]; then
		SwapTotal=$(cat /proc/meminfo | grep SwapTotal| awk '{print $2}')
		if [ -z "$NKN_USB_ROOT" ]; then
			mdev -s
			NKN_USB_ROOT=$(cat /proc/mounts | grep 'AiCard_NKN' | head -n 1 | awk '{print $2}')
			SwapTotal=$(cat /proc/meminfo | grep SwapTotal| awk '{print $2}')
		fi

		while [ -z "$NKN_USB_ROOT" ] || [ "$SwapTotal" -lt "200000" ]; do
			/usr/bin/logger -t nknd Initializing MMC device...
			func_initMMC
			NKN_USB_ROOT=$(cat /proc/mounts | grep 'AiCard_NKN' | head -n 1 | awk '{print $2}')
			SwapTotal=$(cat /proc/meminfo | grep SwapTotal| awk '{print $2}')
		done
	fi

	if [ -z "${NKN_USB_ROOT}" ]; then
		nvram set nkn_enable=0
		nvram commit
		/usr/bin/logger -t nknd Storage device not attached, disable NKN node
		exit 1
	fi

	MemTotal=$(cat /proc/meminfo | grep MemTotal | awk '{print $2}')
	SwapTotal=$(cat /proc/meminfo | grep SwapTotal| awk '{print $2}')

	if [ "$MemTotal" -lt "400000" ]; then
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

		NKN_BENEFICIARY_ADDR=$(nvram get nkn_beneficiary_address)
		if [ "$NKN_BENEFICIARY_ADDR" != "" ]; then
			/usr/bin/logger -t nknd "Beneficiary Address: ${NKN_BENEFICIARY_ADDR}"
			sed -i -e '2i\  "BeneficiaryAddr": "'${NKN_BENEFICIARY_ADDR}'",' "${NKN_USB_ROOT}/nkn/config.json"
		fi
	else
		NKN_RESTART_CNT=$(nvram get nkn_restart_cnt)
		/usr/bin/logger -t nknd "Restart by watchdog($NKN_RESTART_CNT)"
		NKN_RESTART_CNT=$((NKN_RESTART_CNT+1))
		nvram set nkn_restart_cnt=$NKN_RESTART_CNT
	fi

	func_resetChainOnError

	cp -f /etc/storage/nkn/wallet.dat "${NKN_USB_ROOT}/nkn/wallet.dat"

	/usr/bin/logger -t nknd Start NKN node
	export "PATH=$PATH:${NKN_USB_ROOT}/nkn"
	cd "${NKN_USB_ROOT}/nkn"
	echo $NKN_PASSWD > /etc/storage/nkn/wallet.pswd
	nknd </etc/storage/nkn/wallet.pswd >/dev/null 2>&1 &

	nvram set nkn_starting=0
}

func_stop()
{
	if [ -z "$1" ]; then
		/usr/bin/logger -t nknd Stop NKN updater
		kill -9 "`pidof nkn-updater.sh`"
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
reset)
	func_resetChain
	;;
logs)
	func_logs
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
	echo "Usage: $0 {start|stop|info|neighbor|wallet|balance|transfer|reset|logs}"
	exit 1
	;;
esac

exit 0
