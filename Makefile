#!/usr/bin/make -f

.PHONY: help
help:  ## This.
	@perl -ne 'print if /^[^\t ]+:.*## .*$$/' $(MAKEFILE_LIST) \
	| sort \
	| awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

include bin/main.mk

help-goals:  ## Print out a list of all goals and their prerequisites.
	@$(MAKE) -rpn \
	| sed -n -e '/^$$/ { n ; /^[^ $$#][^ ]*:/p ; }' \
	| grep -v '^\.PHONY:' \
	| sort \
	| egrep --color '^[^ ]*:' \
	;
