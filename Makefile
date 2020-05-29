all:
	@echo "make test: rsync dry run"
	@echo "make deploy: rsync the real thing"

test:
	rsync -nav --delete acme.sh deploy dnsapi notify svc:.acme.sh

deploy:
	rsync -av --delete acme.sh deploy dnsapi notify svc:.acme.sh

.PHONY: test deploy
