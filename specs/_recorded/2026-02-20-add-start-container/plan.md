# Plan: add-start-container

## Summary

Implements `scripts/start_container.sh` — the Bash script responsible for pulling the Exasol Docker image, starting the container idempotently, waiting for database readiness, printing connection details, and opening the Admin UI.

## Design

### Goals / Non-Goals

- Goals
    - Start an Exasol container with a single script call, regardless of prior state (no image, image cached, stopped container, running container)
    - Handle all four Docker states idempotently — re-running the script is always safe
    - Surface DSN, username, password, and Admin UI URL clearly to the user
- Non-Goals
    - Installing Docker — handled by a separate installer phase
    - Custom Exasol configuration (passwords, schemas, memory limits)
    - Multi-version image selection

### Architecture

```
scripts/start_container.sh
    │
    ├─ check_image_cached()      → docker image inspect exasol/docker-db:latest
    │       └─ not found → pull_image()   → docker pull exasol/docker-db:latest
    │
    ├─ check_container_state()   → docker inspect --format '{{.State.Status}}' exasol-local
    │       ├─ "running"  → skip to print step
    │       ├─ "exited"   → start_existing() → docker start exasol-local
    │       └─ not found  → create_container() → docker run --name exasol-local \
    │                            -p 127.0.0.1:8563:8563 \
    │                            -p 127.0.0.1:8443:8443 \
    │                            --privileged --stop-timeout 120 --detach \
    │                            exasol/docker-db:latest
    │
    ├─ wait_for_ready()          → poll TCP port 8563, timeout 120 s
    │       └─ timeout → print error, exit 1
    │
    ├─ print_connection_info()   → DSN: localhost:8563 | User: sys | Pass: exasol
    │
    └─ open_admin_ui()           → xdg-open https://localhost:8443
```

### Design Patterns

| Pattern | Where | Why |
|---------|-------|-----|
| Function-per-responsibility | `start_container.sh` | Makes each step independently testable with bats |
| TCP poll loop | `wait_for_ready` | No healthcheck in docker-db image; port polling is portable |
| State machine dispatch | Container state check | Avoids duplicate containers without requiring `--rm` |

### Trade-offs

| Decision | Alternatives Considered | Rationale |
|----------|------------------------|-----------|
| Poll TCP port 8563 for readiness | `docker exec dwad_client`; container health API | TCP poll needs no exec access and works from the host |
| Fixed container name `exasol-local` | Random name; user-configurable name | Idempotency requires a known name to detect existing containers |
| Always use `exasol/docker-db:latest` | Pin a specific version | Simplest for a local dev tool; version pinning is a future concern |

## Features

| Feature | Status | Spec |
|---------|--------|------|
| Start Exasol container | NEW | `installer/start-container/spec.md` |

## Dependencies

- Docker daemon must be running (prerequisite; not checked by this script)
- `nc` or `/dev/tcp` available for TCP readiness polling (present on standard Linux)
- `xdg-open` available for browser launch (standard on Linux desktop environments)

## Implementation Tasks

1. Create `scripts/start_container.sh` with functions: `check_image_cached`, `pull_image`, `check_container_state`, `create_container`, `start_existing`, `wait_for_ready`, `print_connection_info`, `open_admin_ui`
2. Create `tests/start_container.bats` with bats tests covering all five scenarios
3. Create `Makefile` with `test`, `test-remote`, and `lint` targets; `test-remote` copies scripts and tests to the remote machine via SSH and runs `bats` there
4. Install bats-core and helpers (`bats-support`, `bats-assert`) as git submodules under `tests/helpers/`
5. Create `remote/README.md` documenting the expected `remote/host` and `remote/key.pem` files; add `remote/` to `.gitignore`

## Parallelization

| Parallel Group | Tasks |
|----------------|-------|
| Group A | Task 1 (script), Task 2 (tests) — write both, then wire together |
| Group B | Task 3 (Makefile), Task 4 (bats submodules), Task 5 (remote setup) |

Sequential dependencies:
- Group A → verify (tests must run against the script)
- Group B can proceed in parallel with Group A

## Dead Code Removal

None — this is the first implementation.

## Verification

### Checklist

| Step | Command | Expected |
|------|---------|----------|
| Unit tests (local) | `bats tests/` | 0 failures |
| Integration tests (remote) | `make test-remote` | 0 failures on the remote Linux machine |
| Lint | `shellcheck scripts/start_container.sh` | 0 errors/warnings |

### Manual Testing

All manual steps run on the remote Linux machine (SSH in via `ssh -i remote/key.pem $(cat remote/host)`).

| Feature | Test Steps | Expected Result |
|---------|------------|-----------------|
| Start from scratch | 1. `docker rm -f exasol-local 2>/dev/null; docker rmi exasol/docker-db:latest 2>/dev/null`. 2. `bash scripts/start_container.sh` | Image pulled, container starts, DSN/credentials printed, `xdg-open` called with `https://localhost:8443` |
| Already running | 1. Run `bash scripts/start_container.sh` twice | Second run prints details without creating a second container |
| Stopped container | 1. `docker stop exasol-local`. 2. `bash scripts/start_container.sh` | Container restarted, details printed |

### Scenario Verification

| Scenario | Test Type | Test Location |
|----------|-----------|---------------|
| Container starts from scratch | Integration | `tests/start_container.bats` |
| Image already cached | Integration | `tests/start_container.bats` |
| Container already running | Integration | `tests/start_container.bats` |
| Stopped container exists | Integration | `tests/start_container.bats` |
| Database readiness timeout | Unit | `tests/start_container.bats` |
