-include .makerc

DOCKER := docker
GIT := git
SED := sed

CHAR_SPACE=$() $()
CHAR_COMMA=,

var_info = $(info [INFO] $(1)='$($(1))')

# Automatically use Docker buildx plugin when found
BUILDX_ENABLED := $(shell $(DOCKER) buildx version > /dev/null 2>&1 && printf true || printf false)
LATEST_ENABLED ?= true

IMG_REPOSITORY := jq
IMG_VERSION := 1.6
IMG_VARIANT := core
GIT_SHORT_HASH := $(shell $(GIT) rev-parse --short HEAD || printf undefined)

IMG_TAGS := $(IMG_VERSION) \
            v$(IMG_VERSION) \
            $(IMG_VERSION)-git-$(GIT_SHORT_HASH) \
            v$(IMG_VERSION)-git-$(GIT_SHORT_HASH)

ifeq ($(LATEST_ENABLED),true)
    override IMG_TAGS += latest
endif

# Image specific build args
override DOCKER_BUILD_FLAGS += --build-arg JQ_VERSION=$(IMG_VERSION) \
                               --build-arg VARIANT=$(IMG_VARIANT)

DOCKER_BUILDX_PLATFORMS := linux/amd64 \
                           linux/arm64 \
                           linux/arm/v7 \
                           linux/arm/v6 \
                           linux/386 \
                           linux/ppc64le \
                           linux/s390x \
                           linux/riscv64

ifneq ($(IMG_VARIANT), core)
    override IMG_TAGS := $(addsuffix -$(IMG_VARIANT),$(IMG_TAGS))
endif

ifdef IMG_REPOSITORY_PREFIX
    override IMG_REPOSITORY := $(IMG_REPOSITORY_PREFIX)/$(IMG_REPOSITORY)
endif

# Construct '--tag <value>' docker build argument
ifdef IMG_TAGS
    IMG_NAMES := $(foreach t,$(IMG_TAGS),$(IMG_REPOSITORY):$(t))
    s := --tag
    override DOCKER_BUILD_FLAGS += $(s)$(CHAR_SPACE)$(subst $(CHAR_SPACE),$(CHAR_SPACE)$(s)$(CHAR_SPACE),$(strip $(IMG_NAMES)))
endif

# Construct '--platform <value>,<value>' buildx argument
ifeq ($(BUILDX_ENABLED),true)
    override DOCKER := $(DOCKER) buildx $(DOCKER_BUILDX_FLAGS)
    override DOCKER_BUILD_FLAGS += --platform $(subst $(CHAR_SPACE),$(CHAR_COMMA),$(DOCKER_BUILDX_PLATFORMS))
endif

.PHONY: build push info
.DEFAULT_GOAL := build

#@ info        : Print relevant Make variables (useful for debugging)
info:
	$(call var_info,BUILDX_ENABLED)
	$(call var_info,DOCKER_BUILDX_PLATFORMS)
	$(call var_info,IMG_VARIANT)
	$(call var_info,IMG_TAGS)
	$(call var_info,IMG_NAMES)

#@ build       : Build docker image(s)
build:
	$(DOCKER) build . $(DOCKER_BUILD_FLAGS)

#@ push        : Push docker image(s)
push:
ifeq ($(BUILDX_ENABLED),true)
	$(MAKE) DOCKER_BUILD_FLAGS+="--push"
else
	$(DOCKER) push $(IMG_REPOSITORY) $(IMG_NAMES)
endif

#@ help        : This text
help: $(lastword $(MAKEFILE_LIST))
	@$(SED) -n 's/^#@//p' $<
