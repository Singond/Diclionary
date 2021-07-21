PREFIX ?= /usr/local
SRC != find src -type f
INST = dicl

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
