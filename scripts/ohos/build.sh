#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-2.0-or-later
set -euo pipefail

src=$(cd "$(dirname "$0")/../.." && pwd)
: "${OHOS_SDK_HOME:?Set OHOS_SDK_HOME to the Linux SDK directory containing native/}"
: "${OHOS_DEPS_PREFIX:?Set OHOS_DEPS_PREFIX to the target-ABI dependency prefix}"
arch=${TARGET_ARCH:-aarch64}
case "$arch" in
  aarch64) lse=-D__ARM_LSE_ATOMIC_INLINES ;;
  x86_64) lse= ;;
  *) echo "Unsupported TARGET_ARCH: $arch" >&2; exit 2 ;;
esac
native="$OHOS_SDK_HOME/native"
deps="$OHOS_DEPS_PREFIX"
mode=jit
tcg_flags=()
if [ "${QEMU_TCI:-0}" = 1 ]; then
  mode=tci
  tcg_flags+=(--enable-tcg-interpreter)
fi
build=${BUILD_DIR:-"$src/build-ohos-$arch-$mode"}
mkdir -p "$build"
cd "$build"
export PATH="$deps/bin:$PATH"
export PKG_CONFIG_PATH=
export PKG_CONFIG_LIBDIR="$deps/lib/pkgconfig:$deps/share/pkgconfig"
export CC="$native/llvm/bin/$arch-unknown-linux-ohos-clang"
export CXX="$native/llvm/bin/$arch-unknown-linux-ohos-clang++"
export AR="$native/llvm/bin/llvm-ar"
export CFLAGS="$lse -fPIC -D_UAPI_LINUX_VIRTIO_VSOCK_H -D_UAPI_LINUX_VIRTIO_TYPES_H -D_UAPI_LINUX_VIRTIO_RING_H -D_UAPI_LINUX_VIRTIO_PMEM_H -D_UAPI_LINUX_VIRTIO_NET_H -D_UAPI_LINUX_VIRTIO_IOMMU_H -D_UAPI_LINUX_VIRTIO_FS_H -D_UAPI_LINUX_VIRTIO_CONSOLE_H -D_UAPI_LINUX_VIRTIO_CONFIG_H -D_LINUX_SYSINFO_H -UHAVE_OPENAT2_H -D__user= -D__force= -Wno-unused-command-line-argument -I$deps/include -I$deps/include/glib-2.0 -I$deps/lib/glib-2.0/include -I$deps/include/pixman-1"
export LDFLAGS="-L$deps/lib -fuse-ld=lld -Wl,--exclude-libs,ALL"
"$src/configure" --target-list=aarch64-softmmu --cross-prefix= --host-cc=cc \
  -Dohos_embed=true --without-default-features \
  --enable-tcg "${tcg_flags[@]}" --enable-tools --enable-vnc \
  --enable-slirp --enable-virtfs --enable-pixman --enable-attr \
  --disable-modules --disable-linux-user --disable-bsd-user \
  --disable-rust --disable-docs --disable-werror \
  --with-coroutine=sigaltstack --enable-trace-backends=nop \
  --disable-stack-protector --disable-debug-info \
  "$@"
make -j "${JOBS:-$(nproc)}" libqemu-system-aarch64.so libqemu-img.so
if [ "$mode" = tci ]; then
  cp libqemu-system-aarch64.so libqemu-system-aarch64-tci.so
fi
printf 'OHOS %s %s libraries: %s\n' "$arch" "$mode" "$build"
