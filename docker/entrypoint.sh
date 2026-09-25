#!/usr/bin/env bash
#
# Container entrypoint for the dArkOS build.
#
# Runs as root to set up the pieces the native build normally gets from the
# host (binfmt_misc handlers, loop devices, an apt-cacher-ng service), then
# drops to an unprivileged user whose UID/GID match the host caller so files
# written into the bind-mounted repo stay owned by that user.
set -euo pipefail

log() { printf '[darkos-docker] %s\n' "$*"; }

export DARKOS_IN_DOCKER=1

# --- binfmt_misc: lets the debootstrap second stage and every `chroot Arkbuild`
#     call execute arm64/armhf binaries transparently ------------------------
#
# Registered with interpreter /usr/bin/qemu-*-static and the "F" (fix-binary)
# flag so the handler keeps working after chroot into the arm rootfs - which is
# also where the build scripts copy qemu-*-static to. The magic/mask below are
# the standard ELF aarch64 / arm signatures (see /usr/lib/binfmt.d/qemu-*.conf).
register_binfmt() {
  local name="$1" reg="$2"
  [ -w /proc/sys/fs/binfmt_misc/register ] || return 0
  [ -e "/proc/sys/fs/binfmt_misc/${name}" ] && return 0
  if ! { printf '%s' "${reg}" 2>/dev/null > /proc/sys/fs/binfmt_misc/register; } 2>/dev/null; then
    log "WARNING: could not register ${name} binfmt handler"
  fi
}

if [ ! -e /proc/sys/fs/binfmt_misc/register ]; then
  mount -t binfmt_misc none /proc/sys/fs/binfmt_misc 2>/dev/null || \
    log "WARNING: could not mount binfmt_misc (privileged container required)"
fi

register_binfmt qemu-aarch64 ':qemu-aarch64:M::\x7f\x45\x4c\x46\x02\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\xb7\x00:\xff\xff\xff\xff\xff\xff\xff\x00\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xff\xff\xff:/usr/bin/qemu-aarch64-static:OCF'
register_binfmt qemu-arm ':qemu-arm:M::\x7f\x45\x4c\x46\x01\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\x28\x00:\xff\xff\xff\xff\xff\xff\xff\x00\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xff\xff\xff:/usr/bin/qemu-arm-static:OCF'

if [ -e /proc/sys/fs/binfmt_misc/qemu-aarch64 ]; then
  log "binfmt: qemu-aarch64 / qemu-arm handlers active"
else
  log "WARNING: qemu-aarch64 binfmt handler not registered - arm chroots will fail."
  log "         Run once on the host:  docker run --privileged --rm tonistiigi/binfmt --install arm64,arm"
fi

# --- loop devices: needed by setup_partition*.sh / losetup ------------------
modprobe loop 2>/dev/null || true
[ -e /dev/loop-control ] || mknod -m 660 /dev/loop-control c 10 237 2>/dev/null || true
for i in $(seq 0 31); do
  [ -e "/dev/loop${i}" ] || mknod -m 660 "/dev/loop${i}" b 7 "${i}" 2>/dev/null || true
done

# --- apt-cacher-ng: replaces the systemd service stages/prepare.sh starts natively --
if [ "${ENABLE_CACHE:-y}" != "n" ]; then
  install -d -o apt-cacher-ng -g apt-cacher-ng /var/cache/apt-cacher-ng /var/log/apt-cacher-ng /var/run/apt-cacher-ng
  if ! pgrep -x apt-cacher-ng >/dev/null 2>&1; then
    log "starting apt-cacher-ng"
    setpriv --reuid apt-cacher-ng --regid apt-cacher-ng --clear-groups \
      /usr/sbin/apt-cacher-ng -c /etc/apt-cacher-ng \
      PidFile=/var/run/apt-cacher-ng/pid SocketPath=/var/run/apt-cacher-ng/socket \
      ForeGround=0 || log "WARNING: apt-cacher-ng failed to start"
  fi
  for _ in $(seq 1 30); do
    if curl -s -o /dev/null "http://127.0.0.1:3142/acng-report.html"; then
      log "apt-cacher-ng is up on 127.0.0.1:3142"
      break
    fi
    sleep 1
  done
fi

# --- unprivileged build user mapped to the host caller ---------------------
HOST_UID="${HOST_UID:-1000}"
HOST_GID="${HOST_GID:-1000}"
BUILD_USER=builder
BUILD_HOME=/home/builder

if ! getent group "${HOST_GID}" >/dev/null 2>&1; then
  groupadd -g "${HOST_GID}" "${BUILD_USER}"
fi
if getent passwd "${HOST_UID}" >/dev/null 2>&1; then
  BUILD_USER="$(getent passwd "${HOST_UID}" | cut -d: -f1)"
  BUILD_HOME="$(getent passwd "${HOST_UID}" | cut -d: -f6)"
else
  useradd -u "${HOST_UID}" -g "${HOST_GID}" -m -d "${BUILD_HOME}" -s /bin/bash "${BUILD_USER}"
fi

usermod -aG sudo "${BUILD_USER}" 2>/dev/null || true
# Passwordless sudo, and keep the caller's PATH (the build puts ccache and the
# cross toolchain on PATH and then calls `sudo make ...`) - mirrors the
# ark-no-secure-path drop-in the build creates inside the chroots.
# ARCH and CROSS_COMPILE are deliberately NOT kept: every `sudo chroot` would
# carry them into the arm chroots, where premake4 Makefiles put $(ARCH) into
# CFLAGS (breaking libgo2) and configure scripts pick ${CROSS_COMPILE}gcc
# (bypassing the gcc-12 default, breaking retroarch). The host-side `sudo make`
# kernel calls pass both on the command line instead.
{
  printf 'Defaults !secure_path\n'
  printf 'Defaults env_keep += "PATH CCACHE_DIR KCFLAGS"\n'
  printf '%s ALL=(ALL) NOPASSWD: ALL\n' "${BUILD_USER}"
} > /etc/sudoers.d/darkos-nopasswd
chmod 0440 /etc/sudoers.d/darkos-nopasswd

install -d -o "${HOST_UID}" -g "${HOST_GID}" "${BUILD_HOME}"
runuser -u "${BUILD_USER}" -- git config --global --add safe.directory /darkos || true
runuser -u "${BUILD_USER}" -- git config --global http.postBuffer 524288000 || true

log "running as ${BUILD_USER} (${HOST_UID}:${HOST_GID}): $*"
exec gosu "${BUILD_USER}" "$@"
