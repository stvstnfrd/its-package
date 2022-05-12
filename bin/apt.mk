#!/usr/bin/make -f

PACKAGE_NAME=its-package
DEB_DISTROS=$(wildcard src/debian/*) $(wildcard src/ubuntu/*)
DEB_CFGS=$(addsuffix /package.cfg,$(DEB_DISTROS))
CURRENT_VERSION=$(shell \
	grep '^Version:' etc/package.cfg \
	| sed 's/^.*: *//' \
)
GPG=gpg
GPG_SIGNING_ID=$(shell git config user.email)
-include bin/secret.mask

.PHONY: deb
deb:  ## Make all .deb files
	$(MAKE) $(ALL_DEBS)

release: deb $(PUBLIC_KEYS)  ## Update all release files
	$(MAKE) $(RELEASES_GPG) $(IN_RELEASES)
	$(MAKE) $(SOURCES_LISTS)
	$(MAKE) $(BOOTSTRAPS)

%: bin/apt.mk bin/secret.mk

PACKAGES_LISTS=$(addsuffix /Packages,$(subst src/,dist/,$(DEB_DISTROS)))
$(PACKAGES_LISTS):
	cd "$(@D)" && dpkg-scanpackages --multiversion . > Packages
	cd "$(@D)" && gzip -k -f Packages

RELEASES=$(addsuffix /Release,$(subst src/,dist/,$(DEB_DISTROS)))
%/Release: %/Packages
	cd "$(@D)" && apt-ftparchive release . > Release

RELEASES_GPG=$(addsuffix /Release.gpg,$(subst src/,dist/,$(DEB_DISTROS)))
%/Release.gpg: %/Key.gpg %/Release
	cd "$(@D)" && gpg --default-key "$(GPG_SIGNING_ID)" -abs -o - Release > Release.gpg

IN_RELEASES=$(addsuffix /InRelease,$(subst src/,dist/,$(DEB_DISTROS)))
%/InRelease: %/Key.gpg %/Release
	cd "$(@D)" && gpg --default-key "$(GPG_SIGNING_ID)" --clearsign -o - Release > InRelease

SOURCES_LISTS=$(addsuffix /Source.list,$(subst src/,dist/,$(DEB_DISTROS)))
$(SOURCES_LISTS):
	ID="$$(echo "$(@D)" | sed 's@^dist/\([^/]\+\)/\([^/]\+\)@\1@')"; \
	CODENAME="$$(echo "$(@D)" | sed 's@^dist/\([^/]\+\)/\([^/]\+\)@\2@')"; \
	cd "$(@D)" && echo "deb [signed-by=/usr/local/share/keyrings/$(PACKAGE_NAME).gpg] https://raw.githubusercontent.com/stvstnfrd/$(PACKAGE_NAME)/master/dist/$${ID}/$${CODENAME} ./" > Source.list

BOOTSTRAPS=$(addsuffix /Bootstrap.sh,$(subst src/,dist/,$(DEB_DISTROS)))
%/Bootstrap.sh: %/Key.gpg bin/bootstrap.sh
	sed 's@^PACKAGE_KEY=.*$$@PACKAGE_KEY="$(shell cat "$(<)" | base64 --wrap=0)"@' ./bin/bootstrap.sh > "$(@)"

bin/bootstrap.sh: etc/Key.gpg
	sed -i 's@^PACKAGE_KEY=.*$$@PACKAGE_KEY="$(shell cat "$(<)" | base64 --wrap=0)"@' "$(@)"
	curl https://download.docker.com/linux/debian/gpg | gpg --dearmour >etc/Key.docker.gpg
	sed -i 's@^DOCKER_PACKAGE_KEY=.*$$@DOCKER_PACKAGE_KEY="$(shell cat "etc/Key.docker.gpg" | base64 --wrap=0)"@' "$(@)"

PUBLIC_KEYS=$(addsuffix /Key.gpg,$(subst src/,dist/,$(DEB_DISTROS)))
$(PUBLIC_KEYS): etc/Key.gpg
	cp "$(<)" "$(@)"

.PHONY: etc/Key.gpg
etc/Key.gpg:  ## (re)create the public signing key
	if ! $(GPG) --list-keys "$(GPG_SIGNING_ID)" >/dev/null 2>&1; \
	then \
		$(GPG) --full-generate-key; \
	fi
	gpg --export "$(GPG_SIGNING_ID)" > "$(@).new"
	if [ -n "$$(diff "$(@)" "$(@).new" 2>&1)" ]; \
	then \
		mv "$(@).new" "$(@)"; \
		echo "Remade $(@)"; \
	else \
		rm "$(@).new"; \
	fi \
	;

# TODO: Clean this up
dist/%/$(PACKAGE_NAME)_$(CURRENT_VERSION)~debian-bullseye_all.deb: src/%/package.cfg
dist/%/$(PACKAGE_NAME)_$(CURRENT_VERSION)~debian-buster_all.deb: src/%/package.cfg
dist/%/$(PACKAGE_NAME)_$(CURRENT_VERSION)~debian-sid_all.deb: src/%/package.cfg
dist/%/$(PACKAGE_NAME)_$(CURRENT_VERSION)~ubuntu-bionic_all.deb: src/%/package.cfg
dist/%/$(PACKAGE_NAME)_$(CURRENT_VERSION)~ubuntu-impish_all.deb: src/%/package.cfg
dist/%/$(PACKAGE_NAME)_$(CURRENT_VERSION)~ubuntu-jammy_all.deb: src/%/package.cfg
ALL_DEBS:=$(ALL_DEBS) dist/debian/bullseye/$(PACKAGE_NAME)_$(CURRENT_VERSION)~debian-bullseye_all.deb
ALL_DEBS:=$(ALL_DEBS) dist/debian/buster/$(PACKAGE_NAME)_$(CURRENT_VERSION)~debian-buster_all.deb
ALL_DEBS:=$(ALL_DEBS) dist/debian/sid/$(PACKAGE_NAME)_$(CURRENT_VERSION)~debian-sid_all.deb
ALL_DEBS:=$(ALL_DEBS) dist/ubuntu/bionic/$(PACKAGE_NAME)_$(CURRENT_VERSION)~ubuntu-bionic_all.deb
ALL_DEBS:=$(ALL_DEBS) dist/ubuntu/impish/$(PACKAGE_NAME)_$(CURRENT_VERSION)~ubuntu-impish_all.deb
ALL_DEBS:=$(ALL_DEBS) dist/ubuntu/jammy/$(PACKAGE_NAME)_$(CURRENT_VERSION)~ubuntu-jammy_all.deb

$(ALL_DEBS):
	test -d "$(@D)" || mkdir -p "$(@D)"
	cd "$(@D)" && equivs-build "../../../$(dir $(subst dist,src,$(@)))package.cfg"

etc/package.cfg: etc/packages.tsv bin/apt.mk  ## Rebuild the base deb package cfg
	package_version="$$( \
		git log --oneline -- "$(<)" \
		| ./bin/conventional-commits-to-semantic-version \
		| tail -1 \
		| awk '{ print $$1 }' \
	)"; \
	package_version="$${package_version:-0.0.0}"; \
	sed "s/^Version:.*\$$/Version: $${package_version}/" "$(@)" \
	>'$(@).new'; \
	if [ "$(CURRENT_VERSION)" != "$${package_version}" ]; \
	then \
		mv '$(@).new' '$(@)'; \
	else \
		rm '$(@).new'; \
	fi

$(DEB_CFGS): etc/packages.tsv etc/package.cfg  ## Build the deb cfgs
	@get_column() { \
		cat "$${1}" \
			| grep "^$${2}	" \
			| sed "s/^$${2}	//" \
			| cut -d'	' -f$${3} \
			| grep -v '^[ \t]*\$$' \
			| xargs \
			| tr ' ' ',' \
		; \
	} ; \
	basename=$(subst /package,,$(subst src/,,$(basename $(@)))); \
	os="$$(echo "$${basename}" | cut -d'/' -f1)"; \
	version="$$(echo "$${basename}" | cut -d'/' -f2)"; \
	ini_column=1; \
	if [ "$${version}" = 'impish' ]; then ini_column=2; fi ; \
	if [ "$${version}" = 'jammy' ]; then ini_column=2; fi ; \
	if [ "$${version}" = 'sid' ]; then ini_column=2; fi ; \
	if [ "$${version}" = 'bionic' ]; then ini_column=1; fi ; \
	if [ "$${version}" = 'bullseye' ]; then ini_column=1; fi ; \
	if [ "$${version}" = 'buster' ]; then ini_column=1; fi ; \
	shall_packages="$$(get_column $(<) SHALL $${ini_column})"; \
	should_packages="$$(get_column $(<) SHOULD $${ini_column})"; \
	may_packages="$$(get_column $(<) MAY $${ini_column})"; \
	sed \
		-e "s/^Depends:.*$$/Depends: $${shall_packages}/" \
		-e "s/^Recommends:.*$$/Recommends: $${should_packages}/" \
		-e "s/^Suggests:.*$$/Suggests: $${may_packages}/" \
		-e "s/^Version:.*$$/&~$${os}-$${version}/" \
		etc/package.cfg \
		>"$(@)" \
	;
	@echo "Rebuilt: $(@)"
