# OHOS port validation — 2026-11-14

Base: upstream v11.1.3, `005c61c0ef6f6ae615283440b4bb7be51b2c6ddd`.
Reference port: harmoninux/qemu `50ce7096eb6b338bee88a0960c543f93f1b16959`.

Host: Ubuntu under WSL. Toolchain: OpenHarmony Linux native SDK,
Clang 15.0.4 (`feef13a36e78b7a2ff3e9e3f180a958f2782be1e`).
Meson 1.10.1, Ninja 1.13.2. Dependencies reused from the HiSH source-build
pipeline: GLib 2.82.0, Pixman 0.42.2, zlib 1.3.1, PCRE2 10.45,
libffi and their dependencies. QEMU obtains libslirp at its pinned commit
`26be815b86e8d49add8c9a8b320239b9594ff03d`.

| Host ABI | Execution mode | Cross-compile/link | ELF architecture and both entry exports |
| --- | --- | --- | --- |
| AArch64 | JIT (default, including development phones) | PASS | PASS |
| x86_64 | JIT | PASS | PASS |
| AArch64 | TCI (explicit compatibility option) | PASS | PASS |

Every build emulates an AArch64 guest. `scripts/ohos/verify.sh` checked that
both outputs are ELF shared objects with the expected host architecture and
defined, global, default-visible `qemu_system_entry` / `qemu_img_entry` symbols.
The system emulator needs only `libslirp.so.0` and `libc.so`; the image tool
needs only `libc.so`. Both scripts pass `bash -n`.

The host-side mocked-prctl regression test passed: failed permission-switch
calls do not overwrite the errno of the operation they surround.

The first ARM64 build exposed const-member static initialization rejected by
the SDK's Clang 15 in i.MX8MM/i.MX8MP board code. Equivalent automatic const
tables fixed the errors; all three final builds include that fix.

No HarmonyOS device was connected (`hdc list targets` was empty). These checks
establish cross-build/link and binary-interface compatibility, not on-device
JIT authorization, guest boot, VNC, 9p runtime correctness, or performance.
The existing HiSH application libraries were not replaced during this work.
