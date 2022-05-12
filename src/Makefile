#!/usr/bin/make -f
_MAKEFILES ?= $(patsubst %/Makefile,%,$(wildcard */*/*/Makefile))

.PHONY: all
all: $(_MAKEFILES)

.PHONY: $(_MAKEFILES)
$(_MAKEFILES):
	$(MAKE) -C '$(@)' all
