# exasol-local

Get a local [Exasol](https://www.exasol.com) database running in seconds — one command, no configuration.

```sh
curl -fsSL https://raw.githubusercontent.com/juergen-albertsen-exasol/exasol-local/main/install.sh | bash
```

## What it does

1. Pulls the official `exasol/docker-db` Docker image (skipped if already cached)
2. Starts a container named `exasol-local` with sensible defaults
3. Waits until the database accepts connections
4. Prints connection details ready to paste into any SQL client
5. Opens the Admin UI in your browser

The script is **idempotent** — running it again on a machine that already has the container is safe.

## Requirements

- Linux
- [Docker Engine](https://docs.docker.com/engine/install/)
- `sudo` access is used automatically if Docker is not accessible without it

## Connection details

| Field    | Value            |
|----------|------------------|
| DSN      | `localhost:8563` |
| Username | `sys`            |
| Password | `exasol`         |
| Admin UI | https://localhost:8443 |

## Re-running

If the container is already running, the script prints the connection details and exits — no duplicate containers are created. If the container exists but is stopped, it is restarted.

## Development

```sh
# Run unit tests
make test

# Lint
make lint

# Run e2e integration tests (requires remote/host and remote/key.pem)
make e2e-tests
```
