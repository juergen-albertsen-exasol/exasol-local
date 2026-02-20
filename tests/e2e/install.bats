#!/usr/bin/env bats
# End-to-end integration tests for install.sh.
# Run on the remote Linux machine via: make test-remote
# Requires: Docker Engine, sudo access, nc

load ../helpers/bats-support/load
load ../helpers/bats-assert/load

SCRIPT="$BATS_TEST_DIRNAME/../../install.sh"
CONTAINER="exasol-local"

setup_file() {
  # Start from a clean state — remove any existing container
  sudo docker rm -f "$CONTAINER" 2>/dev/null || true
}

teardown_file() {
  # Remove the container after all tests complete
  sudo docker rm -f "$CONTAINER" 2>/dev/null || true
}

@test "install.sh exits successfully and prints connection details" {
  run sudo bash "$SCRIPT"
  assert_success
  assert_output --partial "localhost:8563"
  assert_output --partial "sys"
  assert_output --partial "exasol"
}

@test "container is in running state after install" {
  run sudo docker inspect --format '{{.State.Status}}' "$CONTAINER"
  assert_success
  assert_output "running"
}

@test "database port 8563 accepts TCP connections" {
  run nc -z localhost 8563
  assert_success
}

@test "re-running install.sh is idempotent when container is already running" {
  run sudo bash "$SCRIPT"
  assert_success
  assert_output --partial "already running"
  assert_output --partial "localhost:8563"
}
