#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="/workspace/star-274-kernel"
OUT_DIR="/workspace/star-274-kernel/out"
JOBS="$(nproc)"

export PATH="/opt/toolchains/clang-r383902/bin:/usr/bin:$PATH"

export ARCH=arm64
export SUBARCH=arm64
export CC=clang
export LD=ld.lld
export AR=llvm-ar
export NM=llvm-nm
export OBJCOPY=llvm-objcopy
export OBJDUMP=llvm-objdump
export STRIP=llvm-strip
export READELF=llvm-readelf
export CROSS_COMPILE=aarch64-linux-gnu-
export CLANG_TRIPLE=aarch64-linux-gnu-

cd "$ROOT_DIR"
mkdir -p "$OUT_DIR"

if [ ! -f "$OUT_DIR/.config" ]; then
    cp "$ROOT_DIR/star-5.4.274-ksu.config" "$OUT_DIR/.config"
    make O="$OUT_DIR" ARCH=arm64 CC=clang LD=ld.lld CROSS_COMPILE=aarch64-linux-gnu- CLANG_TRIPLE=aarch64-linux-gnu- olddefconfig
fi

make -j"$JOBS" O="$OUT_DIR" \
    ARCH=arm64 \
    CC=clang \
    LD=ld.lld \
    AR=llvm-ar \
    NM=llvm-nm \
    OBJCOPY=llvm-objcopy \
    OBJDUMP=llvm-objdump \
    STRIP=llvm-strip \
    READELF=llvm-readelf \
    CROSS_COMPILE=aarch64-linux-gnu- \
    CLANG_TRIPLE=aarch64-linux-gnu- \
    LOCALVERSION="" \
    Image dtbs
