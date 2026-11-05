#!/usr/bin/env bash
# Reproducible build for Star 5.4.274 v8 (ReSukiSU + SuSFS v2.3.0).
#
# Prerequisites
#   - toolchain at /opt/toolchains/clang-r383902/bin
#   - KernelSU submodule at the pinned commit (Baka-SU/BakaSU @ 516d3e87)
#   - drivers/kernelsu -> ../KernelSU/kernel symlink present (tracked in git)
#
# The ONLY source change outside .config is
#   ksu-patches/kernelsu-5.4-faccessat-stat-hook-signature.patch
# applied inside the KernelSU submodule. Without it the build panics on the first
# access()/stat() at boot (see README-v8.md).
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT_DIR="${OUT_DIR:-/workspace/kbuild/ksu-v8}"
CONFIG="${CONFIG:-$ROOT_DIR/star-5.4.274-ksu.config}"
JOBS="${JOBS:-$(nproc)}"

export PATH="/opt/toolchains/clang-r383902/bin:/usr/bin:$PATH"
export ARCH=arm64 SUBARCH=arm64
export CC=clang LD=ld.lld AR=llvm-ar NM=llvm-nm
export OBJCOPY=llvm-objcopy OBJDUMP=llvm-objdump STRIP=llvm-strip READELF=llvm-readelf
export CROSS_COMPILE=aarch64-linux-gnu-
export CLANG_TRIPLE=aarch64-linux-gnu-

MAKE_ARGS=(ARCH=arm64 CC=clang LD=ld.lld AR=llvm-ar NM=llvm-nm
           OBJCOPY=llvm-objcopy OBJDUMP=llvm-objdump STRIP=llvm-strip
           READELF=llvm-readelf HOSTCC=gcc
           CROSS_COMPILE=aarch64-linux-gnu- CLANG_TRIPLE=aarch64-linux-gnu-
           LOCALVERSION=)

# 1. KernelSU hook-signature fix (idempotent)
cd "$ROOT_DIR/KernelSU"
if git apply --check "$ROOT_DIR/ksu-patches/kernelsu-5.4-faccessat-stat-hook-signature.patch" 2>/dev/null; then
    git apply "$ROOT_DIR/ksu-patches/kernelsu-5.4-faccessat-stat-hook-signature.patch"
    echo "== applied sucompat 5.4 hook-signature patch"
elif git apply --reverse --check "$ROOT_DIR/ksu-patches/kernelsu-5.4-faccessat-stat-hook-signature.patch" 2>/dev/null; then
    echo "== sucompat 5.4 hook-signature patch already applied"
else
    echo "!! KernelSU tree matches neither state; refusing to build" >&2
    exit 1
fi

# 2. configure + build
cd "$ROOT_DIR"
mkdir -p "$OUT_DIR"
cp "$CONFIG" "$OUT_DIR/.config"
make O="$OUT_DIR" "${MAKE_ARGS[@]}" olddefconfig
make -j"$JOBS" O="$OUT_DIR" "${MAKE_ARGS[@]}" Image dtbs

echo "== Image: $OUT_DIR/arch/arm64/boot/Image"
