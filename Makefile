GIT_TEST ?= bin/git-test
PREFIX ?= bin
DESTDIR ?= $(HOME)
INSTALL_PATH = $(DESTDIR)/$(PREFIX)

all:
	@echo "No default target. Try 'make {test, prove, install}'."

test:
	make -C test test

prove:
	make -C test prove

install: ${GIT_TEST}
	@install -d $(INSTALL_PATH)
	@install -m 644 $(GIT_TEST) $(INSTALL_PATH)
	@echo "Has been installed to $(INSTALL_PATH)"

.PHONY: all test prove
