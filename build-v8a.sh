#!/usr/bin/env bash
# Reproducible v8a build: same source as v8 but SuSFS off, BakaSU manual hook on.
set -euo pipefail
SRC=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
OUT_DIR=${OUT_DIR:-/workspace/kbuild/ksu-v8a}
TC=/opt/toolchains/clang-r383902/bin
export PATH="$TC:$PATH"
cd "$SRC"
# idempotent: the 5.4 faccessat/stat signature fix for the SuSFS body
git -C KernelSU apply --reverse --check ksu-patches/kernelsu-5.4-faccessat-stat-hook-signature.patch 2>/dev/null || true
git -C KernelSU apply ksu-patches/kernelsu-5.4-faccessat-stat-hook-signature.patch 2>/dev/null || true
mkdir -p "$OUT_DIR"
cp -f star-5.4.274-ksu.config "$OUT_DIR/.config"
cd "$OUT_DIR"
"$SRC/scripts/config" -d KSU_SUSFS -d KSU_TRACEPOINT_HOOK -e KSU_MANUAL_HOOK
make -C "$SRC" O="$OUT_DIR" ARCH=arm64 olddefconfig >/dev/null
make -C "$SRC" O="$OUT_DIR" ARCH=arm64 -j"$(nproc)" \
  CC=clang LD=ld.lld AR=llvm-ar NM=llvm-nm OBJCOPY=llvm-objcopy \
  LOCALVERSION= Image
