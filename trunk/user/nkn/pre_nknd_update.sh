#!/bin/sh

if [ -e /dev/mmcblk0 ]; then
	NKN_USB_ROOT=$(cat /proc/mounts | grep 'AiCard_NKN' | head -n 1 | awk '{print $2}')
elif [ -e /dev/sda ]; then
	NKN_USB_ROOT=$(cat /proc/mounts | grep 'AiDisk_' | head -n 1 | awk '{print $2}')
else
	NKN_USB_ROOT=$(cat /proc/mounts | grep 'AiCifs_NKN' | head -n 1 | awk '{print $2}')
fi

FIRMWARE_VER_LOCAL=$(nvram get firmver_sub)
if [ "$FIRMWARE_VER_LOCAL" = "3.4.3.9-099_bxp_nxp" ]; then
	/usr/bin/logger -t firmware "Test firmware found, skip update"
	exit
fi

rm -rf /tmp/firmware
mkdir /tmp/firmware

PRODUCT_ID=$(nvram get productid)
curl --cacert /etc/ssl/certs/ca-certificates.crt --retry 3 --silent -L -o /tmp/firmware/info https://nkn.4h8h.top/padavan/${PRODUCT_ID}.info

FIRMWARE_MD5_REMOTE=$(sed -n '1p' /tmp/firmware/info)
if [ "$(echo ${FIRMWARE_MD5_REMOTE} | wc -m)" != "33" ]; then
	/usr/bin/logger -t firmware "Check update fail, skip firmware update"
	exit
fi

FIRMWARE_VER_REMOTE=$(sed -n '2p' /tmp/firmware/info)
if [ "$FIRMWARE_VER_LOCAL" = "$FIRMWARE_VER_REMOTE" ]; then
	/usr/bin/logger -t firmware "Local firmware(${FIRMWARE_VER_LOCAL}) is up-to-date, continue"
	exit
fi

/usr/bin/logger -t firmware "New firmware(${FIRMWARE_VER_REMOTE}) has been found, downloading..."
curl --cacert /etc/ssl/certs/ca-certificates.crt --retry 10 --silent -L --output ${NKN_USB_ROOT}/nkn/${PRODUCT_ID}_${FIRMWARE_VER_REMOTE}.trx https://nkn.4h8h.top/padavan/${PRODUCT_ID}_${FIRMWARE_VER_REMOTE}.trx
FIRMWARE_MD5_DOWNLOAD=$(md5sum ${NKN_USB_ROOT}/nkn/${PRODUCT_ID}_${FIRMWARE_VER_REMOTE}.trx | awk '{print $1}')

if [ "${FIRMWARE_MD5_DOWNLOAD}" != "${FIRMWARE_MD5_REMOTE}" ]; then
	/usr/bin/logger -t firmware "Firmware download failed, skip update"
	exit
fi

/usr/bin/logger -t firmware "New firmware has been downloaded"

nvram set nkn_starting=1
/usr/bin/logger -t firmware "Stop NKN node"
killall -q nknd

sync; echo 3 >/proc/sys/vm/drop_caches

TMP_FREE=$(df | grep "/tmp" | awk '{print $4}')
if [ "$TMP_FREE" -lt "16000" ]; then
	/usr/bin/logger -t firmware "Free space in /tmp is less than 16M, skip update"
	nvram set nkn_starting=0
	exit
fi

eval $(ldd /sbin/reboot |cut -d'>' -f2 | cut -d' ' -f2 | awk '{print "cp "$1" /tmp/firmware/ ;";}')

mv "${NKN_USB_ROOT}/nkn/${PRODUCT_ID}_${FIRMWARE_VER_REMOTE}.trx" "/tmp/firmware/firmware.trx"
FIRMWARE_MD5_DOWNLOAD=$(md5sum /tmp/firmware/firmware.trx | awk '{print $1}')
if [ "${FIRMWARE_MD5_DOWNLOAD}" = "${FIRMWARE_MD5_REMOTE}" ]; then
	/usr/bin/logger -t firmware "Upgrading firmware..."
	mtd_write -r write /tmp/firmware/firmware.trx Firmware_Stub >${NKN_USB_ROOT}/nkn/${PRODUCT_ID}.log  2>&1
	export LD_LIBRARY_PATH=/tmp/firmware
        /sbin/reboot
else
	rm -rf /tmp/firmware
	nvram set nkn_starting=0
	/usr/bin/logger -t firmware "Check firmware MD5 failed, skip update"
fi

