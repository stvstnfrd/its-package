#!/usr/bin/make -f
CONTAINER_NAME ?= its-package
CONTAINER_VERSION ?= latest
DOCKER ?= docker
DOCKER_OS ?= ubuntu-jammy
DOCKERFILE ?= etc/docker/$(DOCKER_OS).dockerfile
DOCKER_TAG ?= $(CONTAINER_NAME):$(CONTAINER_VERSION)
DOCKER_BUILD ?= $(DOCKER) build --file '$(DOCKERFILE)' --tag '$(DOCKER_TAG)'
DOCKER_RUN=$(DOCKER) run --hostname '$(CONTAINER_NAME)' --rm -it --name '$(CONTAINER_NAME)' '$(DOCKER_TAG)'
DOCKERFILES ?= $(notdir $(basename $(wildcard etc/docker/*.dockerfile)))

.PHONY: docker-build
docker-build:  ## Build a docker container
	$(DOCKER_BUILD) .

.PHONY: docker-sh
docker-sh:  ## Start a container in a POSIX shell
	$(DOCKER_RUN) sh -l

.PHONY: docker-build-all
docker-build-all: $(addprefix docker-build-,$(DOCKERFILES))  ## Build all docker containers

define docker-build-dynamic
.PHONY: docker-build-$(1)
docker-build-$(1):
	$(MAKE) docker-build DOCKER_OS=$(1)
endef

$(foreach dockerfile,$(DOCKERFILES),$(eval $(call docker-build-dynamic,$(dockerfile))))
