# Trust me this is intentional
-include .makerc
ifeq ($(IMG_VERSION),)
    EDGE_ENABLED = true
    override IMG_VERSION = edge
endif
-include .makerc

DOCKER := docker
GIT := git
SED := sed

CHAR_SPACE=$() $()
CHAR_COMMA=,
BUILDARG_PREFIX := .BUILD_

word-dot = $(word $2,$(subst ., ,$1))

ifeq ($(and $(IMG_REPOSITORY),$(IMG_VARIANT)),)
    $(error One or more variables are unset or empty strings. See IMG_REPOSITORY, IMG_VARIANT)
endif

# Automatically use Docker buildx plugin when found
BUILDX_ENABLED := $(shell $(DOCKER) buildx version > /dev/null 2>&1 && printf true || printf false)
LATEST_ENABLED ?= true
EDGE_ENABLED ?= false

# Build images for the following platforms
IMG_PLATFORMS ?= linux/amd64 linux/arm64

IMG_VERSION_MAJOR = $(call word-dot,$(IMG_VERSION),1)
IMG_VERSION_MAJOR_MINOR := $(IMG_VERSION_MAJOR).$(call word-dot,$(IMG_VERSION),2)
GIT_SHORT_HASH := $(shell $(GIT) rev-parse --short HEAD || printf undefined)

IMG_TAGS := $(IMG_VERSION) \
            $(IMG_VERSION)-git-$(GIT_SHORT_HASH)

ifeq ($(EDGE_ENABLED),false)
    override IMG_TAGS += $(IMG_VERSION_MAJOR) \
                         $(IMG_VERSION_MAJOR_MINOR) \
                         v$(IMG_VERSION_MAJOR) \
                         v$(IMG_VERSION_MAJOR_MINOR) \
                         v$(IMG_VERSION)-git-$(GIT_SHORT_HASH) \
                         v$(IMG_VERSION_MAJOR)-git-$(GIT_SHORT_HASH) \
                         v$(IMG_VERSION_MAJOR_MINOR)-git-$(GIT_SHORT_HASH)
endif

ifeq ($(LATEST_ENABLED),true)
    override IMG_TAGS += latest
endif

BUILDARG_VARS := $(filter $(BUILDARG_PREFIX)%,$(.VARIABLES))
BUILDARG_VALS:= $(foreach v, $(BUILDARG_VARS),$(subst $(BUILDARG_PREFIX),,$(v))=$(value $(v)))
override DOCKER_BUILD_FLAGS += $(addprefix --build-arg , $(BUILDARG_VALS))

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
    override DOCKER_BUILD_FLAGS += --platform $(subst $(CHAR_SPACE),$(CHAR_COMMA),$(IMG_PLATFORMS))
else
    $(warning Docker host can only build $(shell $(DOCKER) info --format '{{.Architecture}}') images)
endif

.PHONY: build push
.DEFAULT_GOAL := build

#@ build       : Build docker image(s)
build:
	$(DOCKER) build . $(DOCKER_BUILD_FLAGS)

#@ push        : Push docker image(s)
push:
ifeq ($(BUILDX_ENABLED),true)
	$(MAKE) DOCKER_BUILD_FLAGS+="--push"
else
	@for i in $(IMG_NAMES); do \
    $(DOCKER) push $$i; \
	done
endif

#@ help        : This text
help: $(lastword $(MAKEFILE_LIST))
	@$(SED) -n 's/^#@//p' $<
