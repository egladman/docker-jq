DOCKER := docker

SPACE=$() $()
COMMA=,

REPOSITORY := jq
VERSION := 1.6

TAGS := $(VERSION) v$(VERSION)

override DOCKER_BUILD_FLAGS+=--build-arg JQ_VERSION=$(VERSION)

# Auto enable buildx when available
BUILDX_ENABLED := $(shell docker buildx version > /dev/null 2>&1 && printf true || printf false)
BUILDX_PLATFORMS := linux/amd64 linux/arm64 linux/arm/v7 linux/arm/v6 linux/386 linux/ppc64le linux/s390x
BUILDX_FLAGS :=

ifdef REPOSITORY_PREFIX
    override REPOSITORY := $(REPOSITORY_PREFIX)/$(REPOSITORY)
endif

ifdef TAGS
    TAG_PREFIX := --tag $(REPOSITORY):
    override DOCKER_BUILD_FLAGS += $(TAG_PREFIX)$(subst $(SPACE),$(SPACE)$(TAG_PREFIX),$(strip $(TAGS)))
endif

ifeq ($(BUILDX_ENABLED),true)
    override DOCKER := $(DOCKER) buildx
    override DOCKER_BUILD_FLAGS += --platform $(subst $(SPACE),$(COMMA),$(BUILDX_PLATFORMS))
endif

$(info Docker buildx enabled: $(BUILDX_ENABLED))

.PHONY: image image-push

image:
	$(DOCKER) build . $(DOCKER_BUILD_FLAGS)

image-push:
ifeq ($(BUILDX_ENABLED),true)
	$(MAKE) image DOCKER_BUILD_FLAGS+="--push"
else
	$(DOCKER) push $(REPOSITORY) --all-tags
endif
