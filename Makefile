SHELL = /usr/bin/env bash -o pipefail
.SHELLFLAGS = -ec

P4_PROG_FILE := basic.p4

.PHONY: all
all: build

##@ General

.PHONY: help
help: ## Display this help.
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

##@ Build

.PHONY: p4-build
p4-build: ## Build Docker image name "orf22/passive_rtt:latest".
	docker run --rm -v $(CURDIR)/P4:/p4c p4lang/p4c p4c --target bmv2 --arch v1model $(P4_PROG_FILE)

##@ Dev

.PHONY: tinet-up
tinet-up: ## Set up Virtual Env.
	cd topo && tinet upconf | sudo sh -x

.PHONY: tinet-down
tinet-down: ## Set up Virtual Env.
	cd topo && tinet down | sudo sh -x

.PHONY: tinet-reset
tinet-reset: tinet-down tinet-up ## Reset Virtual Env.

.PHONY: update-image
update-image: build tinet-reset ## Update image and reset virtual Env.