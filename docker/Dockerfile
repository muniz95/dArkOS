# dArkOS build environment
#
# Reproduces the "Ubuntu 24.04+ with passwordless sudo" host that the native
# build expects (see README.md), so `make <device>` can run unchanged inside a
# privileged container on any Docker-capable Linux host.
#
# The repo itself is NOT copied in - it is bind-mounted at /darkos at run time
# by docker-compose.yml, so build outputs land back on the host.
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8

# 32bit userspace tooling is needed by prepare.sh (premake4 / lib32 bits).
RUN dpkg --add-architecture i386 && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
      ca-certificates \
      bc \
      binfmt-support \
      bison \
      btrfs-progs \
      build-essential \
      ccache \
      curl \
      debconf-utils \
      debootstrap \
      device-tree-compiler \
      dosfstools \
      e2fsprogs \
      eatmydata \
      flex \
      gcc \
      gdisk \
      git \
      gosu \
      jq \
      lib32stdc++6 \
      libc6-i386 \
      libncurses5-dev \
      libssl-dev \
      lz4 \
      lzop \
      make \
      netpbm \
      p7zip-full \
      parted \
      python-is-python3 \
      python3 \
      qemu-user-static \
      rsync \
      sudo \
      u-boot-tools \
      xfsprogs \
      xz-utils \
      zlib1g:i386 \
      apt-cacher-ng \
      && \
    rm -rf /var/lib/apt/lists/*

# apt-cacher-ng tuning - same knobs prepare.sh applies on a native host, plus a
# cache dir we can back with a named volume.
RUN sed -i \
      -e "/^# *AllowUserPorts:/c\\AllowUserPorts: 0" \
      -e "/^# *DlMaxRetries:/c\\DlMaxRetries: 50000" \
      -e "/^# *VfileUseRangeOps:/c\\VfileUseRangeOps: 0" \
      -e "/^CacheDir:/c\\CacheDir: /var/cache/apt-cacher-ng" \
      /etc/apt-cacher-ng/acng.conf

COPY docker/entrypoint.sh /usr/local/bin/darkos-entrypoint
RUN chmod +x /usr/local/bin/darkos-entrypoint

WORKDIR /darkos

ENTRYPOINT ["/usr/local/bin/darkos-entrypoint"]
CMD ["bash"]
