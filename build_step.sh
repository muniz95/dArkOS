#!/bin/bash
#
# Run one (or a few) build_*.sh step scripts against a prepared chroot,
# without running a full device build first. This is a debugging/dev-loop
# tool for iterating on a single failing step (e.g. build_retroarch.sh) -
# it does NOT produce a flashable device image.
#
# Usage:
#   UNIT=rg351p STEP=build_retroarch.sh ./build_step.sh
#   UNIT=rg351p STEP="build_sdl2.sh build_retroarch.sh" ./build_step.sh
#
# Or via make / docker-build.sh:
#   make step UNIT=rg351p STEP=build_retroarch.sh
#   ./docker-build.sh step UNIT=rg351p STEP=build_retroarch.sh
#
# Reuse across runs:
#   Arkbuild/ is a loop mount of ArkOS_File_System.img. Under Docker every
#   invocation is a fresh --rm container, so a mount made inside one run does
#   NOT survive into the next one even though the .img file itself persists
#   on the bind-mounted host repo. So on every run this script:
#     1. If Arkbuild/ is already mounted (e.g. reusing a shell inside one
#        container), use it as-is.
#     2. Else, if ArkOS_File_System.img exists on disk, re-mount it onto
#        Arkbuild/ and re-establish the /dev /proc /sys binds - this is the
#        common case across separate `docker-build.sh step` invocations -
#        and skip straight to the requested step(s), since a
#        .arkbuild_prepared marker (written after deps+sdl2 succeed once)
#        confirms deps/sdl2 already ran.
#     3. Else, there's nothing to reuse: run the full prerequisite chain
#        (partition + bootstrap + deps + sdl2) from scratch.
#
# Cleanup: use `make clean` / `./docker-build.sh clean` when done - this
# removes ArkOS_File_System.img along with the mount, so a later `step` run
# starts fresh again.
set -o pipefail

: "${UNIT:?Set UNIT=<device>, e.g. UNIT=rg351p}"
: "${STEP:?Set STEP=<script.sh>, e.g. STEP=build_retroarch.sh}"

if [ -f "build_step.log" ]; then
  ext=1
  while [ -f "build_step.log.${ext}" ]; do
    let ext=ext+1
  done
  mv build_step.log "build_step.log.${ext}"
fi

(
# Deliberately no `set -e` here, matching every build_<device>.sh (e.g.
# build_rg351p.sh) and the step scripts they source: those rely on manual
# `verify_action` / `if [[ $? != 0 ]]` checks and expect to keep running
# past commands that return non-zero as normal control flow (e.g. dpkg -s
# probes in install_package). `set -e` makes the whole subshell exit
# silently on the first such non-zero, with no error text - that's what
# was happening here.

source ./chipset_for_unit.sh
export CHIPSET UNIT

FILESYSTEM="ArkOS_File_System.img"
PREPARED_MARKER="Arkbuild/.arkbuild_prepared"
ROOT_FILESYSTEM_FORMAT="btrfs"
ROOT_FILESYSTEM_MOUNT_OPTIONS="defaults,noatime,compress=zlib:1"

echo "Building step(s) '${STEP}' for UNIT=${UNIT} (CHIPSET=${CHIPSET})"

source ./utils.sh
source ./prepare.sh

reattach_chroot() {
  echo "Found existing ${FILESYSTEM} - re-mounting it onto Arkbuild/."
  mkdir -p Arkbuild/
  sudo mount -t ${ROOT_FILESYSTEM_FORMAT} -o ${ROOT_FILESYSTEM_MOUNT_OPTIONS},loop "${FILESYSTEM}" Arkbuild/
  verify_action
  sudo mount --bind /dev Arkbuild/dev
  verify_action
  sudo mount -t devpts none Arkbuild/dev/pts -o newinstance,ptmxmode=0666
  verify_action
  sudo mount --bind /proc Arkbuild/proc
  verify_action
  sudo mount --bind /sys Arkbuild/sys
  verify_action
  if [ -d "Arkbuild_ccache" ] && ! grep -qs "Arkbuild/home/ark/Arkbuild_ccache " /proc/mounts; then
    sudo mkdir -p Arkbuild/home/ark/Arkbuild_ccache
    sudo mount --bind ${PWD}/Arkbuild_ccache Arkbuild/home/ark/Arkbuild_ccache
    verify_action
  fi
  if ! mountpoint -q Arkbuild; then
    echo "Failed to mount ${FILESYSTEM} onto Arkbuild/ - aborting." >&2
    exit 1
  fi
}

if mountpoint -q Arkbuild 2>/dev/null; then
  echo "Reusing already-mounted Arkbuild/ chroot for ${UNIT} (${CHIPSET})."
elif [ -f "${FILESYSTEM}" ]; then
  reattach_chroot
  if [ ! -f "${PREPARED_MARKER}" ]; then
    echo "Re-mounted Arkbuild/ has no prepared marker - running deps + sdl2 once."
    source ./build_deps.sh
    source ./build_sdl2.sh
    sudo touch "${PREPARED_MARKER}"
  else
    echo "Deps + SDL2 already prepared in this chroot - skipping straight to the requested step(s)."
  fi
else
  echo "No prepared chroot found for ${UNIT} - bootstrapping base system and deps from scratch."
  source ./setup_partition.sh
  source ./bootstrap_rootfs.sh
  source ./build_deps.sh
  source ./build_sdl2.sh
  sudo touch "${PREPARED_MARKER}"
fi

for s in ${STEP}; do
  if [ ! -f "./${s}" ]; then
    echo "Step script './${s}' not found." >&2
    exit 1
  fi
  echo "==> Running ${s}"
  source "./${s}"
done

echo "Step(s) complete: ${STEP}"
echo "Note: Arkbuild/ was left mounted, and ${FILESYSTEM} was left on disk for the next run."
echo "Use 'make clean' (or ./docker-build.sh clean) to tear it down and start fresh."
) 2>&1 | tee -a build_step.log
