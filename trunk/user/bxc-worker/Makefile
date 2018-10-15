SRC_NAME=bxc-worker

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
		--libexecdir=/usr/sbin/bxc-worker \
		--sysconfdir=/etc/storage/bxc-worker \
		--enable-shared \
		--disable-static \
		--enable-icmp \
		--enable-delay-pools \
		--enable-icap-client \
		--enable-kill-parent-hack \
		--disable-snmp \
		--enable-ssl \
		--enable-ssl-crtd \
		--enable-cache-digests \
		--enable-linux-netfilter \
		--disable-unlinkd \
		--enable-x-accelerator-vary \
		--disable-translation \
		--disable-auto-locale \
		--with-dl \
		--with-pthreads \
		--without-expat \
		--without-libxml2 \
		--without-gnutls \
		--without-nettle \
		--with-openssl \
		--enable-epoll \
		--with-maxfd=4096 \
		--disable-external-acl-helpers \
		--disable-auth-negotiate \
		--disable-auth-ntlm \
		--disable-auth-digest \
		--disable-auth-basic \
		--disable-arch-native \
		--with-krb5-config=no \
		--without-mit-krb5 \
		--without-libcap \
		--without-netfilter-conntrack \
		ac_cv_header_linux_netfilter_ipv4_h=yes \
		ac_cv_epoll_works=yes \
		squid_cv_gnu_atomics=no \
		OPENSSL_CFLAGS="-I$(STAGEDIR)/include" \
		OPENSSL_LIBS="-L$(STAGEDIR)/lib -lssl -lcrypto" \
		--host=$(HOST_TARGET) \
		--build=$(HOST_BUILD) ; \
	)

clean:
	if [ -f $(SRC_NAME)/Makefile ] ; then \
		$(MAKE) -C $(SRC_NAME) distclean ; \
	fi ; \
	rm -f config_done

romfs:
	$(STRIP) $(SRC_NAME)/src/bxc-worker
	$(ROMFSINST) $(SRC_NAME)/src/bxc-worker /usr/sbin/bxc-worker
