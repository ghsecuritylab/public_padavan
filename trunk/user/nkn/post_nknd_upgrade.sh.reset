#!/bin/sh

if [ -e /dev/mmcblk0 ]; then
	NKN_USB_ROOT=$(cat /proc/mounts | grep 'AiCard_NKN' | head -n 1 | awk '{print $2}')
elif [ -e /dev/sda ]; then
	NKN_USB_ROOT=$(cat /proc/mounts | grep 'AiDisk_' | head -n 1 | awk '{print $2}')
else
	NKN_USB_ROOT=$(cat /proc/mounts | grep 'AiCifs_NKN' | head -n 1 | awk '{print $2}')
fi

if [ -d "${NKN_USB_ROOT}/nkn/ChainDB" ]; then
	/usr/bin/logger -t nknd "Reset ChainDB directory"
	rm -rf "${NKN_USB_ROOT}/nkn/ChainDB"
fi
