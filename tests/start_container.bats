#!/usr/bin/env bats

load helpers/bats-support/load
load helpers/bats-assert/load

SCRIPT="$BATS_TEST_DIRNAME/../install.sh"

setup() {
  source "$SCRIPT"
  # Make sudo a no-op pass-through so docker() shell mocks are still reachable
  # (real sudo would bypass shell functions and call the docker executable)
  sudo() { "$@"; }
  export -f sudo
}

@test "check_image_cached returns 0 when image exists" {
  docker() { return 0; }
  export -f docker
  run check_image_cached
  assert_success
}

@test "check_image_cached returns 1 when image is absent" {
  docker() { return 1; }
  export -f docker
  run check_image_cached
  assert_failure
}

@test "check_container_state outputs 'running' when container is running" {
  docker() { echo "running"; }
  export -f docker
  run check_container_state
  assert_success
  assert_output "running"
}

@test "check_container_state outputs 'exited' when container is stopped" {
  docker() { echo "exited"; }
  export -f docker
  run check_container_state
  assert_success
  assert_output "exited"
}

@test "check_container_state outputs empty string when container does not exist" {
  docker() { return 1; }
  export -f docker
  run check_container_state
  assert_output ""
}

@test "wait_for_ready succeeds when port is immediately available" {
  nc() { return 0; }
  export -f nc
  READY_TIMEOUT=5 run wait_for_ready
  assert_success
  assert_output --partial "Database is ready"
}

@test "wait_for_ready exits 1 on timeout" {
  nc() { return 1; }
  export -f nc
  READY_TIMEOUT=1 run wait_for_ready
  assert_failure
  assert_output --partial "timed out"
}

@test "print_connection_info prints DSN, user, and password" {
  run print_connection_info
  assert_success
  assert_output --partial "localhost:8563"
  assert_output --partial "sys"
  assert_output --partial "exasol"
}

@test "script pulls image and creates container when starting from scratch" {
  pull_image()            { echo "PULL_CALLED"; }
  check_image_cached()    { return 1; }
  check_container_state() { echo ""; }
  create_container()      { echo "CREATE_CALLED"; }
  wait_for_ready()        { return 0; }
  print_connection_info() { :; }
  open_admin_ui()         { :; }
  export -f pull_image check_image_cached check_container_state create_container
  export -f wait_for_ready print_connection_info open_admin_ui

  run main
  assert_success
  assert_output --partial "PULL_CALLED"
  assert_output --partial "CREATE_CALLED"
}

@test "script does not pull image when already cached" {
  pull_image()            { echo "PULL_CALLED"; }
  check_image_cached()    { return 0; }
  check_container_state() { echo ""; }
  create_container()      { :; }
  wait_for_ready()        { return 0; }
  print_connection_info() { :; }
  open_admin_ui()         { :; }
  export -f pull_image check_image_cached check_container_state create_container
  export -f wait_for_ready print_connection_info open_admin_ui

  run main
  assert_success
  refute_output --partial "PULL_CALLED"
}

@test "script skips container creation when already running" {
  check_image_cached()    { return 0; }
  check_container_state() { echo "running"; }
  create_container()      { echo "CREATE_CALLED"; }
  start_existing()        { echo "START_CALLED"; }
  wait_for_ready()        { return 0; }
  print_connection_info() { :; }
  open_admin_ui()         { :; }
  export -f check_image_cached check_container_state create_container
  export -f start_existing wait_for_ready print_connection_info open_admin_ui

  run main
  assert_success
  refute_output --partial "CREATE_CALLED"
  refute_output --partial "START_CALLED"
}

@test "script restarts stopped container without docker run" {
  check_image_cached()    { return 0; }
  check_container_state() { echo "exited"; }
  start_existing()        { echo "START_CALLED"; }
  create_container()      { echo "CREATE_CALLED"; }
  wait_for_ready()        { return 0; }
  print_connection_info() { :; }
  open_admin_ui()         { :; }
  export -f check_image_cached check_container_state start_existing
  export -f create_container wait_for_ready print_connection_info open_admin_ui

  run main
  assert_success
  assert_output --partial "START_CALLED"
  refute_output --partial "CREATE_CALLED"
}
