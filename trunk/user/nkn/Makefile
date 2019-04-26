all:

romfs:
	$(ROMFSINST) -p +x /usr/bin/nkn.sh
	$(ROMFSINST) -p +x /usr/bin/nkn-updater.sh
ifeq ($(CONFIG_FIRMWARE_INCLUDE_NKN_WITH_BINARY),y)
	mkdir -p $(ROMFSDIR)/usr/share/nkn
	$(ROMFSINST) /usr/share/nkn/nkn.tgz
	$(ROMFSINST) /usr/share/nkn/nkn.md5
endif

clean:
	echo "Clean nkn romfs"
