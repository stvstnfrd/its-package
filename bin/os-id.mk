-include ../../bin/secret.mk
ARCHIVE_ROOT=.
COMPONENTS=$(patsubst %/Makefile,%,$(wildcard dists/*/Makefile))

.PHONY: all
all: Bootstrap.sh Key.gpg dists  ## Build the repository for an entire OS

.PHONY: dists
dists: $(COMPONENTS)  ## Build the repository indices for all dists

.PHONY: $(COMPONENTS)
$(COMPONENTS):  ## Build the repository indices for a specific dist
	$(MAKE) -C '$(@)'

Bootstrap.sh: Key.gpg ../../bin/bootstrap.sh
	sed 's@^PACKAGE_KEY=.*$$@PACKAGE_KEY="$(shell cat '$(<)' | base64 --wrap=0)"@' ../../bin/bootstrap.sh >'$(@)'

FINGERPRINT_ACTUAL=$(shell \
	gpg \
		--show-keys \
		--with-fingerprint \
		--with-colons \
		Key.gpg \
	| awk \
		-F':' \
		'$12 == "s" {print $5}' \
)
FINGERPRINT_LIVE=$(shell \
	gpg \
		--list-keys \
		--with-fingerprint \
		--with-colons \
		'$(GPG_SIGNING_ID)' \
	| awk \
		-F':' \
		'$12 == "s" {print $5}' \
)

ifneq ($(FINGERPRINT_LIVE),$(FINGERPRINT_ACTUAL))
.PHONY: Key.gpg
endif
Key.gpg:
	gpg --export '$(GPG_SIGNING_ID)' >'$(@)'

help-goals:  ## Print out a list of all goals and their prerequisites.
	@$(MAKE) -rpn \
	| sed -n -e '/^$$/ { n ; /^[^ $$#][^ ]*:/p ; }' \
	| grep -v '^\.PHONY:' \
	| sort \
	| egrep --color '^[^ ]*:' \
	;
