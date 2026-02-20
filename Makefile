BATS := tests/helpers/bats-core/bin/bats

.PHONY: test e2e-tests lint

test:
	$(BATS) tests/start_container.bats

e2e-tests:
	$(BATS) tests/e2e/install.bats

lint:
	shellcheck install.sh
