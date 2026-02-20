# Tasks: add-start-container

## Group B: Infrastructure
- [x] 4. Install bats-core and helpers (`bats-support`, `bats-assert`) as git submodules under `tests/helpers/`
- [x] 5. `remote/README.md` and `.gitignore` for remote/ — already done

## Group A: Script + Tests (TDD)
- [x] 2. Create `tests/start_container.bats` with bats tests covering all five scenarios (RED)
- [x] 1. Create `scripts/start_container.sh` with all required functions (GREEN)

## Group B: Makefile
- [x] 3. Create `Makefile` with `test`, `test-remote`, and `lint` targets

## Phase 3: Verification
- [x] Run `bats tests/` — 11/11 passed
- [x] Run `shellcheck scripts/start_container.sh` — 0 errors/warnings
