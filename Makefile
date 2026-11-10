-include env_make

include base-images.mk

NETBIRD_VER ?= 0.82.1
NETBIRD_DASHBOARD_VER ?= v2.96.1
NETBIRD_VER_MINOR = $(shell echo "${NETBIRD_VER}" | grep -oE '^[0-9]+\.[0-9]+')

TAG ?= $(NETBIRD_VER_MINOR)

REPO = wodby/netbird
NAME = netbird-$(NETBIRD_VER)

IMAGETOOLS_TAG ?= $(TAG)

ifneq ($(ARCH),)
	override TAG := $(TAG)-$(ARCH)
endif

.PHONY: check-pins build test push shell run clean buildx-imagetools-create

default: build

# The pinned NetBird images must be the versions being built.
check-pins:
	$(if $(filter netbirdio/netbird-server:$(NETBIRD_VER)@%,$(BUILD_IMAGE_NETBIRD_SERVER)),,$(error base-images.mk pins no netbird-server $(NETBIRD_VER)))
	$(if $(filter netbirdio/relay:$(NETBIRD_VER)@%,$(BUILD_IMAGE_NETBIRD_RELAY)),,$(error base-images.mk pins no relay $(NETBIRD_VER)))
	$(if $(filter netbirdio/dashboard:$(NETBIRD_DASHBOARD_VER)@%,$(BUILD_IMAGE_NETBIRD_DASHBOARD)),,$(error base-images.mk pins no dashboard $(NETBIRD_DASHBOARD_VER)))

build: check-pins
	docker build -t $(REPO):$(TAG) \
		--build-arg BASE_IMAGE="$(BASE_IMAGE)" \
		--build-arg NETBIRD_SERVER_IMAGE="$(BUILD_IMAGE_NETBIRD_SERVER)" \
		--build-arg NETBIRD_RELAY_IMAGE="$(BUILD_IMAGE_NETBIRD_RELAY)" \
		--build-arg NETBIRD_DASHBOARD_IMAGE="$(BUILD_IMAGE_NETBIRD_DASHBOARD)" \
		--build-arg NETBIRD_VER=$(NETBIRD_VER) \
		--build-arg NETBIRD_DASHBOARD_VER=$(NETBIRD_DASHBOARD_VER) \
		./

test:
	cd ./tests && IMAGE=$(REPO):$(TAG) NAME=$(NAME) NETBIRD_VER=$(NETBIRD_VER) ./run.sh

push:
	docker push $(REPO):$(TAG)

buildx-imagetools-create:
	docker buildx imagetools create -t $(REPO):$(IMAGETOOLS_TAG) \
				$(REPO):$(TAG)-amd64 \
				$(REPO):$(TAG)-arm64

shell:
	docker run --rm --name $(NAME) -i -t $(PORTS) $(VOLUMES) $(ENV) $(REPO):$(TAG) /bin/bash

run:
	docker run --rm --name $(NAME) -p 8080:8080 -p 8082:8082 $(PORTS) $(VOLUMES) $(ENV) $(REPO):$(TAG) $(CMD)

clean:
	-docker rm -f $(NAME)
