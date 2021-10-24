PREFIX ?= /usr/local
all_files != git ls-files
src_files != find src -type f
installables = dicl
version != grep "version:" shard.yml | cut -d " " -f2
distbase = diclionary-$(version)
distfile = $(distbase).tar.gz

all: $(installables)

dicl: $(src_files)
	crystal build --release src/dicl.cr

.PHONY: check
check: $(src_files)
	crystal spec

.PHONY: install
install: $(installables)
	@echo "Installing $(DESTDIR)$(PREFIX)/bin/dicl"
	install -d $(DESTDIR)$(PREFIX)/bin/
	install -m 755 dicl $(DESTDIR)$(PREFIX)/bin/
	install -d $(DESTDIR)$(PREFIX)/share/man/man1/
	install -m 644 doc/dicl.1 $(DESTDIR)$(PREFIX)/share/man/man1/

.PHONY: uninstall
uninstall:
	rm -f $(DESTDIR)$(PREFIX)/bin/dicl
	rm -f $(DESTDIR)$(PREFIX)/share/man/man1/dicl.1

dist: $(distfile)
$(distfile): $(all_files)
	git archive --prefix $(distbase)/ -o $@ HEAD
