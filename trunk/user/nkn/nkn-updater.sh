#!/bin/sh

/usr/bin/logger -t nknd Start NKN updater

if [ -e /dev/mmcblk0 ]; then
	NKN_USB_ROOT=$(cat /proc/mounts | grep 'AiCard_NKN' | head -n 1 | awk '{print $2}')
else
	NKN_USB_ROOT=$(cat /proc/mounts | grep 'dev.*.media' | head -n 1 | awk '{print $2}')
fi

while true; do
	sleep 86400

	NKN_MD5_LOCAL=$(cat /usr/share/nkn/nkn.md5)

	if [ -f "${NKN_USB_ROOT}/nkn/nkn.tgz" ]; then
		NKN_MD5_LOCAL=$(md5sum "${NKN_USB_ROOT}/nkn/nkn.tgz" | awk '{print $1}')
	fi

	NKN_MD5_REMOTE=$(curl --cacert /etc/ssl/certs/ca-certificates.crt --retry 3 --silent -L https://github.com/bettermanbao/nkn/releases/download/latest/nkn.md5)
	if [ "$(echo ${NKN_MD5_REMOTE} | wc -m)" != "33" ]; then
		/usr/bin/logger -t nknd "Update failed, continue"
		continue
	fi

	if [ "${NKN_MD5_LOCAL}" != "${NKN_MD5_REMOTE}" ]; then
		/usr/bin/logger -t nknd New version of NKN node has been found, downloading...
		while [ "${NKN_MD5_DOWNLOAD}" != "${NKN_MD5_REMOTE}" ]; do
			curl --cacert /etc/ssl/certs/ca-certificates.crt --retry 10 --silent -L --output ${NKN_USB_ROOT}/nkn/nkn-latest.tgz https://github.com/bettermanbao/nkn/releases/download/latest/nkn.tgz
			NKN_MD5_DOWNLOAD=$(md5sum ${NKN_USB_ROOT}/nkn/nkn-latest.tgz | awk '{print $1}')
			/usr/bin/logger -t nknd New version of NKN node has been downloaded
		done
		mv "${NKN_USB_ROOT}/nkn/nkn-latest.tgz" "${NKN_USB_ROOT}/nkn/nkn.tgz"

		nvram set nkn_starting=1

		/usr/bin/logger -t nknd Stop NKN node
		killall -q nknd

		tar -xzvf "${NKN_USB_ROOT}/nkn/nkn.tgz" -C "${NKN_USB_ROOT}/nkn"

		/usr/bin/logger -t nknd Start NKN node
		export "PATH=$PATH:${NKN_USB_ROOT}/nkn"
		cd "${NKN_USB_ROOT}/nkn"
		nknd </etc/storage/nkn/wallet.pswd >/dev/null 2>&1 &

		nvram set nkn_starting=0
	else
		if [ -f "${NKN_USB_ROOT}/nkn/nkn.tgz" ]; then
			/usr/bin/logger -t nknd "Local NKN node(USB) is up-to-date, continue"
		else
			/usr/bin/logger -t nknd "Local NKN node(ROM) is up-to-date, continue"
		fi
	fi
done
