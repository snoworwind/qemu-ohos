# QEMU for HarmonyOS / OpenHarmony

This fork tracks official stable QEMU releases and carries a small OHOS
embedding patch set. The `ohos-11.1` branch starts at upstream **v11.1.3**
(`005c61c0ef6f6ae615283440b4bb7be51b2c6ddd`).

The runtime adaptations are based on
[harmoninux/qemu, hish-libqemu](https://github.com/harmoninux/qemu/tree/50ce7096eb6b338bee88a0960c543f93f1b16959).
Upstream QEMU licenses and copyright notices remain applicable.

## Adaptations

- Opt-in `-Dohos_embed=true`: build `libqemu-system-aarch64.so` and
  `libqemu-img.so`, exporting `qemu_system_entry(int, char **)` and
  `qemu_img_entry(int, char **)`. GLib/GModule are linked statically.
- Normal system-emulator shutdown returns to its caller rather than calling
  `exit()`. The ordinary executable path is retained when embedding is off.
- OHOS-only JITFORT permission switching around executable `mmap`/`mprotect`,
  preserving the memory operation's errno.
- OHOS-only workaround for `chmod` on 9p mapped-file metadata in shared storage.
- A reproducible cross-build entry point for ARM64 and x86_64 hosts, both
  emulating an AArch64 guest, with optional TCI instead of JIT.
- Clang 15 compatibility for i.MX8MM/i.MX8MP local device tables: use automatic
  const initialization where the SDK compiler rejects static initialization
  from another const object's members.

## Build on Linux / WSL

Install a Linux-host OpenHarmony native SDK, Python, Meson, Ninja, Make,
pkg-config and a host C compiler. Prepare **target-ABI** dependencies compiled
with PIC: GLib (including GIO/GModule), libffi, PCRE2, zlib, zstd and Pixman.
Their pkg-config prefixes must resolve to the installed target libraries.
The HiSH source dependency pipeline can supply these dependencies:
[build-source-linux.sh](https://github.com/snoworwind/HiSH/blob/master/scripts/build-source-linux.sh).
QEMU's pinned subprojects, including libslirp, are obtained by its build system;
the first build requires network access or a populated subproject cache.

```sh
export OHOS_SDK_HOME=/path/to/ohos-sdk/linux
export OHOS_DEPS_PREFIX=/path/to/ohos-arm64-deps
scripts/ohos/build.sh

# x86_64 HarmonyOS emulator host; supply x86_64 dependencies too
TARGET_ARCH=x86_64 OHOS_DEPS_PREFIX=/path/to/ohos-x86_64-deps \
  scripts/ohos/build.sh

# Interpreter build for devices without JIT permission
QEMU_TCI=1 scripts/ohos/build.sh
```

JIT is the default for development builds on phones as well as tablets/PCs.
Do not choose TCI just because the device is a phone. In HiSH, the application
selects the JIT library for development bundle IDs; TCI remains an explicit
compatibility option for distributions that cannot use JIT.

`BUILD_DIR` and `JOBS` override the output directory and build concurrency.
Extra arguments are passed to QEMU configure, for example `--enable-lto`.
Outputs live in `build-ohos-<host-arch>-<jit|tci>/`; a TCI build also creates
`libqemu-system-aarch64-tci.so`. Package the corresponding libslirp shared library
alongside the emulator. Keep builds on a native Linux filesystem under WSL.

Check ELF architecture and entry-point exports after building:

```sh
scripts/ohos/verify.sh build-ohos-aarch64-jit aarch64
scripts/ohos/verify.sh build-ohos-x86_64-jit x86_64
```

The errno-preservation regression test runs on a Linux host without an OHOS
device (the platform call is deliberately mocked to fail):

```sh
cc -D__OHOS__ -Iinclude scripts/ohos/test-jit-errno.c \
  -Wl,--wrap=prctl -o /tmp/qemu-ohos-test-jit-errno
/tmp/qemu-ohos-test-jit-errno
```

See [validation record](docs/ohos-validation-2026-11-14.md) for the builds
actually checked and the remaining device-test boundary.

## Embedding limitations

These are command-line entry points, not a reentrant VM object API. Other QEMU
paths (including argument errors and some qemu-img commands) still call `exit()`
or register process-global state. Do not assume safe repeated initialization or
multiple VM instances within one process. Use process isolation where required.
JIT also requires permission from the device's platform policy; this fork does
not grant that permission. The 9p workaround follows the reference port and
relies on the application sandbox for metadata access control on OHOS.

Keep upstream `master` separate from OHOS changes. Start future release branches
from an official stable tag, then port and validate the small patch set.
