SRC_NAME=tinyproxy

all: config_test
	$(MAKE) -C $(SRC_NAME)

config_test:
	( if [ -f ./config_done ]; then \
		echo "the same configuration"; \
	else \
		make configure && touch config_done; \
	fi )

configure:
	( cd $(SRC_NAME) ; \
	./configure \
		--prefix="" \
		--sysconfdir=/usr/share \
		ac_cv_func_malloc_0_nonnull=yes \
		ac_cv_func_realloc_0_nonnull=yes \
		--host=$(HOST_TARGET) \
		--build=$(HOST_BUILD) ; \
	)

clean:
	if [ -f $(SRC_NAME)/Makefile ] ; then \
		$(MAKE) -C $(SRC_NAME) distclean ; \
	fi ; \
	rm -f config_done

romfs:
	$(STRIP) $(SRC_NAME)/src/tinyproxy
	$(ROMFSINST) $(SRC_NAME)/src/tinyproxy /usr/sbin/bxc-worker
	mkdir -p $(ROMFSDIR)/usr/share/tinyproxy
	cp -f tinyproxy.conf $(ROMFSDIR)/usr/share/tinyproxy/tinyproxy.conf

