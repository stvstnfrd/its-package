ARCH ?= amd64
COMPONENT ?= main
DIR_BIN ?= ../../../../bin
DIR_DIST ?= ../../../../dist
PACKAGE_CFGS ?= $(wildcard build/*.cfg)

.PHONY: help
help:  ## This.
	@perl -ne 'print if /^[a-zA-Z_.-]+:.*## .*$$/' $(MAKEFILE_LIST) \
	| sort \
	| awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

define get-package-name
grep '^Source:' '$(1)' \
| sed 's@^Source: *@@'
endef

define get-upstream-version
grep '^Version:' '$(1)' \
| sed -e 's@^[^-]*-@@'
endef

define get-version-now
grep '^Version:' '$(1)' \
| sed -e 's@^Version:\s*@@' \
| cut -d'-' -f1
endef

define get-version-next
$(DIR_BIN)/git-log-version '.' '$(DIR_BIN)'
endef

define get-architecture
grep '^Architecture:' '$(1)' \
| sed -e 's@^Architecture:\s*@@'
endef

define get-package-base-next
printf '%s_%s-%s' \
'$(shell $(call get-package-name,$(1)))' \
'$(shell $(call get-version-next,$(1)))' \
'$(shell $(call get-upstream-version,$(1)))'
endef

define get-deb-name
printf '%s_%s.deb' \
'$(shell $(call get-package-base-next,$(1)))' \
'$(shell $(call get-architecture,$(1)))'
endef

define update-package-cfg
	sed \
		-e "s/^Version:.\([^-]*\)-/Version: $$(shell $$(call get-version-next,$(1)))-/" \
		'$(1)' \
	>'$(1).tmp' \
	; \
	if ! diff '$(1)' '$(1).tmp' 2>/dev/null; then \
		mv '$(1).tmp' '$(1)'; \
		echo 'Rebuilt: $(1)'; \
	else \
		rm '$(1).tmp'; \
	fi
endef

define get-dist
echo "$(basename $(notdir $(1)))" | cut -d'-' -f2
endef

define get-id
echo "$(basename $(notdir $(1)))" | cut -d'-' -f1
endef

define get-deb-path
$(DIR_DIST)/$$(shell $$(call get-id,$(1)))/pool/$$(shell $$(call get-dist,$(1)))/$(COMPONENT)/$$(shell $$(call get-package-name,$(1)) | sed 's@^\(.\).*$$$$@\1@')/$$(shell $$(call get-package-name,$(1)))/$$(shell $$(call get-deb-name,$(1)))
endef

define make-rules-cfg
ALL_DEBS += $(call get-deb-path,$(1))

$(call get-deb-path,$(1)): $(1)
	test -d "$$(dir $$(@))" || mkdir -p "$$(dir $$(@))"; \
	cd '$$(dir $$(@))' \
	&& equivs-build --arch '$(ARCH)' '$(abspath $(1))'
	# repack the DEB using GZIP; Debian doesn't support ZSTD until DEB12
	tempdir=$$$$(mktemp -d); \
	dpkg-deb -R '$$(@)' "$$$${tempdir}"; \
	dpkg-deb -Zgzip -b "$$$${tempdir}" '$$(@)'; \
	rm -rf "$$$${tempdir}"
	git add '$$(@)'
	# git add '$$(dir $$(@))'

ifneq ($$(shell $$(call get-version-now,$(1))), $$(shell $$(call get-version-next,$(1))))
.PHONY: $(1)
endif

$(1):
	@export PATH="$$(DIR_BIN):$${PATH}"; \
	$(call update-package-cfg,$$(@))
	git add '$(1)'

endef

$(foreach cfg,$(PACKAGE_CFGS),$(eval $(call make-rules-cfg,$(cfg))))

.PHONY: cfg
cfg: $(PACKAGE_CFGS)  ## Update the version number in config files

.PHONY: all
all: $(ALL_DEBS) ## Build the latest version of the .deb
	if [ -n "$$(git diff --cached .)" ]; then \
		git commit -m 'chore: bump $(shell $(call get-package-name,$(firstword $(PACKAGE_CFGS))))==$(shell $(call get-version-next,$(firstword $(PACKAGE_CFGS))))'; \
	fi

help-goals:  ## Print out a list of all goals and their prerequisites.
	@$(MAKE) -rpn \
	| sed -n -e '/^$$/ { n ; /^[^ $$#][^ ]*:/p ; }' \
	| grep -v '^\.PHONY:' \
	| sort \
	| egrep --color '^[^ ]*:' \
	;
