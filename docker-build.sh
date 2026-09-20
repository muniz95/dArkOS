#!/usr/bin/env bash
#
# Run the dArkOS build inside a Docker container instead of on a bare-metal
# Ubuntu host. See the "Building with Docker" section of README.md.
#
#   ./docker-build.sh rg353m           # build an image for a device
#   ./docker-build.sh devenv           # build a dev chroot only
#   ./docker-build.sh clean            # run `make clean`
#   ./docker-build.sh shell            # interactive shell in the build env
#   ./docker-build.sh --rebuild <tgt>  # rebuild the Docker image first
#
# Build knobs work exactly like the native make, passed through from your env:
#   BUILD_KODI=y ./docker-build.sh rg353m
#   DEBIAN_CODE_NAME=sid BUILD_ARMHF=n ./docker-build.sh rgb30
#
# This wrapper only needs the Docker CLI. A docker-compose.yml is also provided
# for those who prefer `docker compose run --rm builder make <target>`.
set -euo pipefail

cd "$(dirname "$(readlink -f "$0")")"

IMAGE=darkos-builder:latest
APTCACHE_VOLUME=darkos-aptcache
REBUILD=0

if [ "${1:-}" = "--rebuild" ]; then
  REBUILD=1
  shift
fi

if [ "$#" -eq 0 ]; then
  cat <<'EOF'
Usage: ./docker-build.sh [--rebuild] <target>

Common targets (anything the Makefile accepts also works):
  Devices : a10mini g350 miniloong rgb10 rgb20pro rgb30 rg351mp
            rg351p rg353m rg353v rg503 rk2023
  Dev env : devenv  devenv32
  Cleanup : clean  clean_devenv  clean_devenv32  clean_complete
  Other   : shell   (interactive bash in the build environment)

Env vars forwarded to the build (same as native make):
  DEBIAN_CODE_NAME  ENABLE_CACHE  BUILD_KODI  BUILD_ARMHF  BUILD_BLUEALSA
EOF
  exit 1
fi

if ! command -v docker >/dev/null 2>&1; then
  echo "docker not found. Install Docker Engine." >&2
  exit 1
fi

if [ "$REBUILD" -eq 1 ] || ! docker image inspect "$IMAGE" >/dev/null 2>&1; then
  echo ">> Building $IMAGE ..."
  docker build -t "$IMAGE" -f docker/Dockerfile .
fi

HOST_UID="$(id -u)"
HOST_GID="$(id -g)"
export HOST_UID HOST_GID

# Interactive tty only when we actually have one (keeps CI / pipes happy).
if [ -t 0 ]; then TTY_FLAGS=(-it); else TTY_FLAGS=(-i); fi

RUN_ARGS=(
  --rm
  "${TTY_FLAGS[@]}"
  --privileged
  -v "$PWD":/darkos
  -v /dev:/dev
  -v "$APTCACHE_VOLUME":/var/cache/apt-cacher-ng
  -w /darkos
  -e HOST_UID -e HOST_GID
  -e DEBIAN_CODE_NAME -e ENABLE_CACHE -e BUILD_KODI -e BUILD_ARMHF -e BUILD_BLUEALSA
)

if [ "$1" = "shell" ]; then
  exec docker run "${RUN_ARGS[@]}" "$IMAGE" bash
fi

exec docker run "${RUN_ARGS[@]}" "$IMAGE" make "$@"
