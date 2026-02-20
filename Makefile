REMOTE_HOST_FILE := remote/host
REMOTE_KEY       := remote/key.pem
REMOTE_USER      ?= ubuntu
REMOTE_DIR       := ~/exa-local
BATS             := tests/helpers/bats-core/bin/bats

.PHONY: test test-remote lint

test:
	$(BATS) tests/

test-remote: $(REMOTE_HOST_FILE) $(REMOTE_KEY)
	$(eval REMOTE_HOST := $(shell cat $(REMOTE_HOST_FILE)))
	rsync -az --delete \
		-e "ssh -i $(REMOTE_KEY) -o StrictHostKeyChecking=no" \
		scripts/ tests/ \
		$(REMOTE_USER)@$(REMOTE_HOST):$(REMOTE_DIR)/
	ssh -i $(REMOTE_KEY) -o StrictHostKeyChecking=no \
		$(REMOTE_USER)@$(REMOTE_HOST) \
		"cd $(REMOTE_DIR) && bats tests/"

lint:
	shellcheck scripts/start_container.sh
