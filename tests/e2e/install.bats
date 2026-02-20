#!/usr/bin/env bats
# End-to-end integration test for install.sh.
#
# Runs locally. Each step SSHes to the remote Linux host and executes
# commands there, simulating exactly what a real user would do.
#
# Prerequisites (see remote/README.md):
#   remote/host     — hostname or IP of the remote Linux machine
#   remote/key.pem  — SSH private key with access to that machine
#
# Run via: make e2e-tests

load ../helpers/bats-support/load
load ../helpers/bats-assert/load

REMOTE_HOST_FILE="$BATS_TEST_DIRNAME/../../remote/host"
REMOTE_KEY="$BATS_TEST_DIRNAME/../../remote/key.pem"
REMOTE_USER="${REMOTE_USER:-ubuntu}"
INSTALL_CMD="curl -fsSL https://raw.githubusercontent.com/juergen-albertsen-exasol/exasol-local/main/install.sh | bash"
CONTAINER="exasol-local"

# Helper: run a command on the remote host via SSH
ssh_remote() {
  local host
  host="$(cat "$REMOTE_HOST_FILE")"
  ssh -i "$REMOTE_KEY" -o StrictHostKeyChecking=no "${REMOTE_USER}@${host}" "$@"
}

setup_file() {
  # Ensure a clean slate before the suite runs
  ssh_remote "sudo docker rm -f $CONTAINER 2>/dev/null || true"
}

teardown_file() {
  # Remove the container after all tests complete
  ssh_remote "sudo docker rm -f $CONTAINER 2>/dev/null || true"
}

@test "curl | sh exits successfully and prints connection details" {
  run ssh_remote "$INSTALL_CMD"
  assert_success
  assert_output --partial "localhost:8563"
  assert_output --partial "sys"
  assert_output --partial "exasol"
}

@test "container exasol-local is running on remote host" {
  run ssh_remote "sudo docker inspect --format '{{.State.Status}}' $CONTAINER"
  assert_success
  assert_output "running"
}

@test "database port 8563 accepts TCP connections on remote host" {
  run ssh_remote "nc -z localhost 8563"
  assert_success
}

@test "re-running install is idempotent when container is already running" {
  run ssh_remote "$INSTALL_CMD"
  assert_success
  assert_output --partial "already running"
  assert_output --partial "localhost:8563"
}
