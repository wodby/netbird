-include env_make

NETBIRD_VER ?= 0.82.0
NETBIRD_DASHBOARD_VER ?= v2.96.0
NETBIRD_VER_MINOR = $(shell echo "${NETBIRD_VER}" | grep -oE '^[0-9]+\.[0-9]+')

TAG ?= $(NETBIRD_VER_MINOR)

REPO = wodby/netbird
NAME = netbird-$(NETBIRD_VER)

IMAGETOOLS_TAG ?= $(TAG)

ifneq ($(ARCH),)
	override TAG := $(TAG)-$(ARCH)
endif

.PHONY: build test push shell run clean buildx-imagetools-create

default: build

build:
	docker build -t $(REPO):$(TAG) \
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
