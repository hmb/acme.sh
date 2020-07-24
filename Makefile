NAME=acme-sh
BINNAME=acme.sh
ETCDIR=$(DESTDIR)/etc/$(NAME)
BINDIR=$(DESTDIR)/usr/bin
LIBDIR=$(DESTDIR)/usr/lib/$(NAME)
LOGDIR=$(DESTDIR)/var/log/$(NAME)
VARLIBDIR=$(DESTDIR)/var/lib/$(NAME)
LOGROTDIR=$(DESTDIR)/etc/logrotate.d
# the installed symlink is relative to the bin
FINALBIN=../lib/$(NAME)/$(BINNAME)

all:
	echo "there's no default target use the following targets:"
	echo " :install:"
	echo " :clean:"
	echo " :test:"
	echo " :find:"

install:
	install -d $(BINDIR)/
	install -d $(ETCDIR)
	install -d $(LOGDIR)
	./acme.sh --install  \
		--home $(LIBDIR) \
		--config-home $(VARLIBDIR) \
		--cert-home $(VARLIBDIR)/certs \
		--noprofile \
		--nocron
	ln -s $(FINALBIN) $(BINDIR)
	install --mode=644 conf/acme-sh.conf $(ETCDIR)/
	install --mode=644 conf/account.conf $(VARLIBDIR)/
	install -d $(VARLIBDIR)/.ssh
	install conf/ssh.conf $(VARLIBDIR)/.ssh/config
	install -d $(LOGROTDIR)
	install --mode=644 conf/logrotate $(LOGROTDIR)/acme-sh

debian:
	debuild -uc -us

# test targets to install into the test dir xxx
DESTDIRTEST=$(shell pwd)/xxx

clean: DESTDIR=$(DESTDIRTEST)
clean:
	rm -rf $(DESTDIR)

test: export DESTDIR=$(DESTDIRTEST)
test: clean install
	rm -r $(DESTDIR)/usr/lib/$(NAME)/deploy
	rm -r $(DESTDIR)/usr/lib/$(NAME)/dnsapi
	rm -r $(DESTDIR)/usr/lib/$(NAME)/notify

find: DESTDIR=$(DESTDIRTEST)
find: test
	find $(DESTDIR) | sort

.PHONY: all install debian clean test find
