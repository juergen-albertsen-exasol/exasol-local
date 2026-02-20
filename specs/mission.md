# Mission: exasol-local

## Purpose

exasol-local is a single-line installer that sets up a local Exasol database instance
on a developer's machine using Docker. It exists to eliminate the manual complexity of
the current docker-db setup process so that Data Scientists and Data Engineers can get
Exasol running locally in seconds.

## Problem

Data Scientists and Data Engineers frequently need a local Exasol instance for development,
experimentation, and testing. The current best path — the official
[docker-db](https://github.com/exasol/docker-db) — requires users to manually handle
Docker installation, container configuration, port mapping, and credential lookup. This
friction slows onboarding and discourages local experimentation.

No existing tool provides a true zero-configuration, single-command local Exasol setup.

## Target Users

| Persona | Goal | Workflow |
|---|---|---|
| Data Scientist | Run SQL queries against Exasol locally without infrastructure help | Paste one command, connect their SQL client, start querying |
| Data Engineer | Develop and test Exasol pipelines locally before deploying | Spin up a local instance quickly, iterate, tear down |

## Core Capabilities

1. **Single-command installation** — one `curl | sh` command installs everything needed
2. **Docker auto-install** — detects whether Docker Engine is present; installs it if not
3. **Exasol container setup** — pulls and starts the official Exasol Docker image with sensible defaults
4. **Connection details output** — prints DSN, username, and password ready to paste into any SQL client
5. **Admin UI launch** — automatically opens the Exasol Admin UI in the default browser

## Out of Scope

- **Windows** — not supported
- **macOS** — deferred; Linux is the initial target platform
- **Production or cloud deployment** — local development use only; not hardened for production
- **Exasol SaaS / Cloud** — self-hosted Docker only, no Exasol Cloud provisioning
- **Custom Exasol configuration** — default container settings only; no advanced tuning
- **Multi-node clusters** — single-node local setup only
- **Kubernetes** — no Helm charts, no k8s manifests

## Domain Glossary

| Term | Meaning in this project |
|---|---|
| **DSN** | Data Source Name — the connection string (host:port) used by SQL clients to connect to Exasol |
| **docker-db** | The official Exasol Docker image at [exasol/docker-db](https://github.com/exasol/docker-db) |
| **Admin UI** | The Exasol web-based administration interface, served by the container on a known port |
| **exasol-local** | This project — the installer script and supporting test infrastructure |
| **remote machine** | A Linux host used for integration testing; credentials stored in `remote/` (gitignored) |

## Tech Stack

| Layer | Technology |
|---|---|
| Installer | Bash |
| Container runtime | Docker Engine (Linux) |
| Database | Exasol via [exasol/docker-db](https://github.com/exasol/docker-db) |
| Testing | [bats](https://github.com/bats-core/bats-core) (Bash Automated Testing System) |
| Linting | [shellcheck](https://www.shellcheck.net/) |

## Commands

| Purpose | Command |
|---|---|
| Run installer locally | `bash install.sh` |
| Run unit tests locally | `bats tests/` |
| Run integration tests on remote machine | `make test-remote` |
| Lint scripts | `shellcheck install.sh` |
| Install end-to-end (as users would) | `curl https://downloads.exasol.com/exasol-local \| sh` |

## Project Structure

```
exasol-local/
├── install.sh              # Main installer — pulls image, starts container, waits, prints details, opens UI
├── tests/
│   ├── start_container.bats  # bats tests for container lifecycle
│   └── helpers/              # bats helper libraries (bats-support, bats-assert)
├── remote/                 # Gitignored — SSH credentials for the remote test machine
│   └── README.md           # Documents expected files (host, key.pem)
├── specs/
│   └── mission.md          # This file
└── Makefile                # Targets: test, test-remote, lint
```

## Architecture

The installer is a single orchestration script with a linear flow:

```
curl | sh
    │
    ├─ 1. Check Docker presence (docker info)
    │       └─ Not found → install Docker Engine (scripts/docker_linux.sh)
    ├─ 2. Pull Exasol Docker image (docker pull exasol/docker-db:latest)
    ├─ 3. Start container (docker run with fixed ports and default credentials)
    ├─ 4. Wait for readiness (poll TCP port 8563)
    ├─ 5. Print connection details (DSN, username, password)
    └─ 6. Open Admin UI (xdg-open https://localhost:8443)
```

Container lifecycle logic lives in `install.sh` and is directly testable via bats.

## Constraints

- **Linux only** — initial target platform; macOS support is deferred
- **No runtime dependencies** beyond what the script installs — users run it on a fresh machine
- **Non-destructive** — re-running the installer on a machine that already has Docker and
  Exasol running must be safe (idempotent)
- **Integration tests run on a remote Linux machine** — credentials (hostname + PEM key) are
  stored in `remote/` which is gitignored; see `remote/README.md` for setup instructions
