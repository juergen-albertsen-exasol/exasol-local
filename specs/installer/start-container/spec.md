# Feature: Start Exasol Container

Starts a local Exasol database container and surfaces connection details so a user can immediately connect with any SQL client.

## Background

- Docker is installed and the Docker daemon is running.
- The container is always named `exasol-local`.
- The Exasol Docker image used is `exasol/docker-db:latest`.
- The database SQL port is `8563` mapped to `localhost:8563`.
- The Admin UI port is `8443` mapped to `localhost:8443`.
- Default credentials are username `sys` and password `exasol`.
- The script is idempotent: running it multiple times MUST NOT create duplicate containers.

## Scenarios

### Scenario: Container starts from scratch

* *GIVEN* Docker is running
* *AND* no container named `exasol-local` exists
* *AND* the `exasol/docker-db` image is not present locally
* *WHEN* `install.sh` is executed
* *THEN* the script SHALL pull the `exasol/docker-db:latest` image
* *AND* the script SHALL create and start a container named `exasol-local` with `--privileged`, `--stop-timeout 120`, port `8563` and port `8443` exposed on localhost
* *AND* the script SHALL wait until the database accepts TCP connections on port `8563`
* *AND* the script SHALL print the DSN (`localhost:8563`), username (`sys`), and password (`exasol`) to stdout
* *AND* the script SHALL open `https://localhost:8443` via `xdg-open`

### Scenario: Image already cached

* *GIVEN* Docker is running
* *AND* no container named `exasol-local` exists
* *AND* the `exasol/docker-db:latest` image is already present locally
* *WHEN* `install.sh` is executed
* *THEN* the script SHALL NOT invoke `docker pull`
* *AND* the script SHALL create and start the container
* *AND* the script SHALL print connection details and open the Admin UI via `xdg-open` via `xdg-open`

### Scenario: Container already running

* *GIVEN* Docker is running
* *AND* a container named `exasol-local` is already in the running state
* *WHEN* `install.sh` is executed
* *THEN* the script SHALL NOT start a new container
* *AND* the script SHALL NOT invoke `docker run` or `docker start`
* *AND* the script SHALL print connection details to stdout
* *AND* the script SHALL open `https://localhost:8443` via `xdg-open`

### Scenario: Stopped container exists

* *GIVEN* Docker is running
* *AND* a container named `exasol-local` exists but is in the stopped state
* *WHEN* `install.sh` is executed
* *THEN* the script SHALL start the existing container with `docker start exasol-local`
* *AND* the script SHALL NOT invoke `docker run`
* *AND* the script SHALL wait until the database accepts TCP connections on port `8563`
* *AND* the script SHALL print connection details and open the Admin UI via `xdg-open`

### Scenario: Database readiness timeout

* *GIVEN* Docker is running
* *AND* no container named `exasol-local` exists
* *WHEN* `install.sh` is executed
* *AND* the database does not accept TCP connections on port `8563` within 120 seconds
* *THEN* the script SHALL print an error message indicating the startup timed out
* *AND* the script SHALL exit with a non-zero status code

## Test Coverage

| Scenario | Test type | File |
|---|---|---|
| Container starts from scratch | E2E | `tests/e2e/install.bats` |
| Image already cached | Unit | `tests/start_container.bats` |
| Container already running | Unit + E2E | `tests/start_container.bats`, `tests/e2e/install.bats` |
| Stopped container exists | Unit | `tests/start_container.bats` |
| Database readiness timeout | Unit | `tests/start_container.bats` |
| Port 8563 accepts connections after install | E2E | `tests/e2e/install.bats` |

E2E tests run on the remote Linux machine via `make test-remote`. They use `sudo` (Docker requires root on the remote host), remove any pre-existing container before the run, and remove it again on teardown.
