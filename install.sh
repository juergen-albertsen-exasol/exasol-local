#!/usr/bin/env bash
set -euo pipefail

CONTAINER_NAME="exasol-local"
IMAGE="exasol/docker-db:latest"
SQL_PORT=8563
ADMIN_PORT=8443
STOP_TIMEOUT=120
POLL_INTERVAL=1
READY_TIMEOUT="${READY_TIMEOUT:-120}"

# Sets DOCKER to "docker" if the daemon is reachable without sudo, else "sudo docker".
detect_docker_cmd() {
  if docker info > /dev/null 2>&1; then
    DOCKER="docker"
  else
    DOCKER="sudo docker"
  fi
}

# Returns 0 if the Docker image is already present locally.
check_image_cached() {
  $DOCKER image inspect "$IMAGE" > /dev/null 2>&1
}

# Pulls the Docker image from the registry.
pull_image() {
  echo "Pulling $IMAGE ..."
  $DOCKER pull "$IMAGE"
}

# Outputs the current state of the named container, or empty string if absent.
check_container_state() {
  $DOCKER inspect --format '{{.State.Status}}' "$CONTAINER_NAME" 2>/dev/null || true
}

# Creates and starts a new detached container.
create_container() {
  echo "Creating and starting container $CONTAINER_NAME ..."
  $DOCKER run \
    --name "$CONTAINER_NAME" \
    -p "127.0.0.1:${SQL_PORT}:${SQL_PORT}" \
    -p "127.0.0.1:${ADMIN_PORT}:${ADMIN_PORT}" \
    --privileged \
    --stop-timeout "$STOP_TIMEOUT" \
    --detach \
    "$IMAGE"
}

# Starts an existing stopped container.
start_existing() {
  echo "Starting existing container $CONTAINER_NAME ..."
  $DOCKER start "$CONTAINER_NAME"
}

# Polls TCP port $SQL_PORT until the database accepts connections or timeout.
wait_for_ready() {
  local elapsed=0
  echo "Waiting for database on port $SQL_PORT (timeout ${READY_TIMEOUT}s) ..."
  while ! nc -z localhost "$SQL_PORT" 2>/dev/null; do
    if (( elapsed >= READY_TIMEOUT )); then
      echo "ERROR: database startup timed out after ${READY_TIMEOUT}s" >&2
      return 1
    fi
    sleep "$POLL_INTERVAL"
    elapsed=$(( elapsed + 1 ))
  done
  echo "Database is ready."
}

# Prints DSN, username, password, and Admin UI URL to stdout.
print_connection_info() {
  echo ""
  echo "Connection details:"
  echo "  DSN:      localhost:${SQL_PORT}"
  echo "  Username: sys"
  echo "  Password: exasol"
  echo "  Admin UI: https://localhost:${ADMIN_PORT}"
}

# Opens the Admin UI in the default browser (best-effort; silent on failure).
open_admin_ui() {
  xdg-open "https://localhost:${ADMIN_PORT}" > /dev/null 2>&1 || true
}

main() {
  detect_docker_cmd
  if ! check_image_cached; then
    pull_image
  fi

  local state
  state="$(check_container_state)"

  case "$state" in
    running)
      echo "Container $CONTAINER_NAME is already running."
      ;;
    exited)
      start_existing
      wait_for_ready
      ;;
    *)
      create_container
      wait_for_ready
      ;;
  esac

  print_connection_info
  open_admin_ui
}

(return 0 2>/dev/null) || main "$@"
