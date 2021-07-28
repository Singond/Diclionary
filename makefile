PREFIX ?= /usr/local
all != git ls-files
SRC != find src -type f
INST = dicl
version != cat version
versionnum != grep -Eo '[0-9.]+' version
distbase = diclionary-$(version)
distfile = $(distbase).tar.gz

all: $(INST)

dicl: $(SRC)
	crystal build --release src/dicl.cr

.PHONY: install
install: $(INST)
	install -d $(DESTDIR)$(PREFIX)/bin/
	install -m 755 dicl $(DESTDIR)$(PREFIX)/bin/

.PHONY: uninstall
uninstall:
	rm -f $(DESTDIR)$(PREFIX)/bin/dicl

dist: $(distfile)
$(distfile): $(all)
	git archive --prefix $(distbase)/ -o $@ HEAD
