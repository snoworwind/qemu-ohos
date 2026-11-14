#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-2.0-or-later
set -euo pipefail
build=${1:?Usage: verify.sh BUILD_DIRECTORY [aarch64|x86_64]}
arch=${2:-aarch64}
case "$arch" in
  aarch64) machine=AArch64 ;;
  x86_64) machine='Advanced Micro Devices X86-64' ;;
  *) echo "Unsupported architecture: $arch" >&2; exit 2 ;;
esac
readelf=${READELF:-readelf}
for entry in qemu-system-aarch64:qemu_system_entry qemu-img:qemu_img_entry; do
  name=${entry%%:*}
  symbol=${entry##*:}
  library="$build/lib$name.so"
  header=$("$readelf" -h "$library")
  grep -q 'Type:.*DYN' <<< "$header"
  grep -q "Machine:.*$machine" <<< "$header"
  symbols=$("$readelf" --dyn-syms --wide "$library")
  awk -v symbol="$symbol" '$5 == "GLOBAL" && $6 == "DEFAULT" && $7 != "UND" && $8 == symbol {found=1} END {exit !found}' <<< "$symbols"
  printf 'PASS %s: %s, exported %s\n' "$library" "$arch" "$symbol"
  "$readelf" -d "$library" | grep NEEDED || true
done
