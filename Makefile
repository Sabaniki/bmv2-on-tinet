SHELL = /usr/bin/env bash -o pipefail
.SHELLFLAGS = -ec

P4_PROG_FILE := basic.p4


##@ General

.PHONY: help
help: ## Display this help.
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

##@ Build

.PHONY: p4-build
p4-build: ## Build P4 source code.
	docker run --rm -v $(CURDIR)/P4:/p4c p4lang/p4c p4c --target bmv2 --arch v1model $(P4_PROG_FILE) --p4runtime-files p4info.txt

.PHONY: custom-image
custom-image: ## Build Docker image named "sabaniki/bmv2:latest".
	cd bmv2 && docker build -t sabaniki/bmv2 .

.PHONY: env
env: p4-build bmv2-docker-build tinet-reset  ## Create virtual network environment.

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

##@ Run

.PHONY: run
run: ## run P4 switch (exec before `make set-config`)
	docker exec -it P4 simple_switch src/basic.json -i 1@vm1 -i 2@vm2 -i 3@vm3 --nanolog ipc:///tmp/bm-0-log.ipc --log-console -L debug --notifications-addr ipc:///tmp/bmv2-0-notifications.ipc

.PHONY: set-config
set-config: ## set runtime config to P4 switch (exec after `make run`)
	docker exec -it P4 bash -c "cat src/runtime.txt | bm_CLI"

##@ Attach

.PHONY: cli
cli: ## attach bmv2 runtime cli
	docker exec -it P4 bm_CLI

.PHONY: events
events: ## attach bmv2 nanomsg_events
	docker exec -it P4 bm_nanomsg_events
