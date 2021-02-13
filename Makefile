prefix ?= /usr/local
bindir = $(prefix)/bin

build:
	swift build -c release --disable-sandbox

install: build
	install ".build/release/mshare" "$(bindir)"

uninstall:
	rm -rf "$(bindir)/mshare"

clean:
	rm -rf .build

.PHONY: build install uninstall clean
