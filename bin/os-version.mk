-include ../../../../bin/secret.mk
ARCHITECTURES=$(subst binary-,,$(notdir $(wildcard */binary-*)))
ARCHIVE_ROOT=../..
POOL=$(ARCHIVE_ROOT)/pool
CODENAME=$(notdir $(realpath $(CURDIR)))
COMPONENTS=$(patsubst %/,%,$(wildcard */))
ID=$(notdir $(realpath $(CURDIR)/../..))
LABEL=
ORIGIN=https://raw.githubusercontent.com/stvstnfrd/$(REPO_NAME)/master/dist/$(ID)/dists/$(CODENAME)
REPO_NAME=its-package
SUITE=stable
TITLE=Its The Simple (meta) Package
VERSION=
ALL_DEBS=$(shell find '$(POOL)/$(CODENAME)' -name '*.deb')

PACKAGES=$(addsuffix /Packages,$(wildcard */binary-*))
PACKAGES_GZ=$(addsuffix .gz,$(PACKAGES))
ifneq (,$(COMPONENTS))
CONTENTS=$(addsuffix $(ARCHITECTURES),$(addsuffix /Contents-,$(COMPONENTS)))
CONTENTS_GZ=$(addsuffix .gz,$(CONTENTS))
else
CONTENTS=
CONTENTS_GZ=
endif

.PHONY: all
all: InRelease Release Release.gpg Source.list $(COMPONENTS)
	if [ -n "$$(git diff $(^))" ]; then \
		git add $(^); \
		git commit -m 'chore: update index; $(CODENAME)'; \
	fi

Release: $(CONTENTS_GZ)
	echo 'Title: $(TITLE)' >'$(@)'
ifneq (,$(ORIGIN))
	echo 'Origin: $(ORIGIN)' >>'$(@)'
endif
ifneq (,$(LABEL))
	echo 'Label: $(LABEL)' >>'$(@)'
endif
ifneq (,$(VERSION))
	echo 'Version: $(VERSION)' >>'$(@)'
endif
ifneq (,$(SUITE))
	echo 'Suite: $(SUITE)' >>'$(@)'
endif
ifneq (,$(CODENAME))
	echo 'Codename: $(CODENAME)' >>'$(@)'
endif
ifneq (,$(COMPONENTS))
	echo 'Components: $(COMPONENTS)' >>'$(@)'
endif
ifneq (,$(ARCHITECTURES))
	echo 'Architectures: $(ARCHITECTURES)' >>'$(@)'
endif
	apt-ftparchive release ./ >>'$(@)'

Release.gpg: Release
	gpg --default-key "$(GPG_SIGNING_ID)" -abs -o - '$(<)' >'$(@)'

InRelease: Release Release.gpg
	gpg --default-key "$(GPG_SIGNING_ID)" --clearsign -o - '$(<)' >'$(@)'

.PHONY: Source.list
Source.list:
	echo 'deb [signed-by=/usr/local/share/keyrings/$(REPO_NAME).gpg] https://raw.githubusercontent.com/stvstnfrd/$(REPO_NAME)/master/dist/$(ID)/ $(CODENAME) main' >'$(@)'

define target-component
$(1): $(addprefix $(1)/Contents-,$(ARCHITECTURES)) \
	$(addsuffix .gz,$(addprefix $(1)/Contents-,$(ARCHITECTURES))) \
	$(addprefix $(1)/binary-,$(ARCHITECTURES))

$(addprefix $(1)/Contents-,$(ARCHITECTURES)):
$(1)/Contents-%: $(1)/binary-%/Packages.gz
	( \
		cd '$$(ARCHIVE_ROOT)' \
		&& apt-ftparchive \
			contents pool/$$(CODENAME)/$(1) \
	) \
	>'$$(@)'

$(addsuffix .gz,$(addprefix $(1)/Contents-,$(ARCHITECTURES))):
$(1)/Contents-%.gz: $(1)/Contents-%
	gzip -k -f <'$$(<)' >'$$(@)'

$(addprefix $(1)/binary-,$(ARCHITECTURES)): \
	$(addsuffix /Packages.gz,$(addprefix $(1)/binary-,$(ARCHITECTURES))) \
	$(addsuffix /Packages,$(addprefix $(1)/binary-,$(ARCHITECTURES)))

$(addsuffix /Packages.gz,$(addprefix $(1)/binary-,$(ARCHITECTURES))):
$(1)/binary-%/Packages.gz: $(1)/binary-%/Packages
	gzip -k -f <'$$(<)' >'$$(@)'

$(addsuffix /Packages,$(addprefix $(1)/binary-,$(ARCHITECTURES))): $(1)/binary-%/Packages: $(wildcard $$(addsuffix *_%.deb,$$(wildcard $(POOL)/$(CODENAME)/$(1)/*/*/))) \
		$(ALL_DEBS)
	( \
		cd '$(ARCHIVE_ROOT)' \
		&& apt-ftparchive \
			--arch '$$(*)' \
			packages pool/$(CODENAME)/$(1)/ \
	) \
	>'$$(@)'

endef
$(foreach component,$(COMPONENTS),$(eval $(call target-component,$(component))))

help-goals:  ## Print out a list of all goals and their prerequisites.
	@$(MAKE) -rpn \
	| sed -n -e '/^$$/ { n ; /^[^ $$#][^ ]*:/p ; }' \
	| grep -v '^\.PHONY:' \
	| sort \
	| egrep --color '^[^ ]*:' \
	;
