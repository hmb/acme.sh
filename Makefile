DESTDIR=~/project/acme.sh/xxx
NAME=acme.sh
ETCDIR=$(DESTDIR)/etc/$(NAME)
BINDIR=$(DESTDIR)/usr/bin
LIBDIR=$(DESTDIR)/usr/lib/$(NAME)
LOGDIR=$(DESTDIR)/var/log/$(NAME)
VARLIBDIR=$(DESTDIR)/var/lib/$(NAME)

all:
	echo all

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

ic:
	rm -rf $(DESTDIR)
	rm -rf ~/.acme.sh/

it: ic install

if: it
	find $(DESTDIR)

.PHONY: all install ic if it
