SRC_NAME=bxc-network

CFLAGS += -ffunction-sections -fdata-sections
LDFLAGS += -Wl,--gc-sections

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
	autoreconf -vi ; \
	IFCONFIG=/sbin/ifconfig \
	ROUTE=/sbin/route \
	NETSTAT=/bin/netstat \
	./configure \
		--prefix=/usr \
		--disable-debug \
		--disable-plugins \
		--disable-pkcs11 \
		--disable-ofb-cfb \
		--disable-selinux \
		--disable-systemd \
		--disable-iproute2 \
		--disable-management \
		--disable-socks \
		--enable-small \
		--enable-multi \
		--enable-server \
		--enable-multihome \
		--enable-pf \
		--enable-fragment \
		--enable-http-proxy \
		--enable-def-auth \
		--enable-ssl \
		--enable-crypto \
		--enable-lzo \
		--with-crypto-library=openssl \
		OPENSSL_CRYPTO_CFLAGS="-I$(STAGEDIR)/include" \
		OPENSSL_CRYPTO_LIBS="-L$(STAGEDIR)/lib -lcrypto" \
		OPENSSL_SSL_CFLAGS="-I$(STAGEDIR)/include" \
		OPENSSL_SSL_LIBS="-L$(STAGEDIR)/lib -lssl -lcrypto" \
		LZO_CFLAGS="-I$(STAGEDIR)/include" \
		LZO_LIBS="-L$(STAGEDIR)/lib -llzo2" \
		--with-sysroot=$(STAGEDIR) \
		--host=$(HOST_TARGET) \
		--build=$(HOST_BUILD) ; \
	)

clean:
	rm -f config_done

romfs:
	$(STRIP) $(SRC_NAME)/src/bxcnetwork/bxc-network
	$(ROMFSINST) $(SRC_NAME)/src/bxcnetwork/bxc-network /usr/sbin/bxc-network
	$(ROMFSINST) -p +x /usr/bin/bxc.sh
	$(ROMFSINST) -p +x /usr/bin/bxc-json.sh
	$(ROMFSINST) -p +x /usr/bin/bxc-watchdog.sh

