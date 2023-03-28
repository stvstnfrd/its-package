#!/usr/bin/make -f
dists=$(patsubst %/Makefile,%,$(wildcard dist/*/Makefile))

.PHONY: all
all: src dist  ## Build everything, source and distribution

.PHONY: src
src:  ## Build source packages
	$(MAKE) -C src

.PHONY: dists
dist: $(dists)  ## Build the distribution index

.PHONY: $(dists)
$(dists):
	$(MAKE) -C '$(@)'

include bin/docker.mk
