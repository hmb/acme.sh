NAME=acme.sh
ETCDIR=$(DESTDIR)/etc/$(NAME)
BINDIR=$(DESTDIR)/usr/bin
LIBDIR=$(DESTDIR)/usr/lib/$(NAME)
LOGDIR=$(DESTDIR)/var/log/$(NAME)
VARLIBDIR=$(DESTDIR)/var/lib/$(NAME)

all:
	echo "there's no0 default target use the following targets:"
	echo " :install:
	echo " :test-clean:
	echo " :testinst:
	echo " :find:

install:
	install -d $(BINDIR)/
	install -d $(ETCDIR)
	install -d $(LOGDIR)
	./acme.sh --install  \
		--home $(LIBDIR) \
		--config-home $(VARLIBDIR) \
		--cert-home $(VARLIBDIR)/issued  \
		--accountconf $(ETCDIR)/account.conf \
		--noprofile \
		--nocron
	ln -s $(LIBDIR)/$(NAME) $(BINDIR)
	install --mode=644 account.conf $(ETCDIR)/

# test targets to install into the test dir xxx
DESTDIRTEST=$(shell pwd)/xxx

test-clean: DESTDIR=$(DESTDIRTEST)
test-clean:
	rm -rf $(DESTDIR)
	rm -rf ~/.acme.sh/

testinst: export DESTDIR=$(DESTDIRTEST)
testinst: test-clean install

find: DESTDIR=$(DESTDIRTEST)
find:
	find $(DESTDIR) | sort

.PHONY: all install test-clean testinst find
