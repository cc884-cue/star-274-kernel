#!/usr/bin/env bash
# Build an AnyKernel3 flashable zip for the star (Mi 11 Ultra) kernel.
#
# usage: make-ak3.sh <Image> <out.zip> "<kernel.string>"
#
# Ships the raw `Image` (matching the published v7/v8 zips) and keeps the AK3
# template's tools/META-INF intact. Device check is `star`/`mars`.
set -euo pipefail

IMAGE=$(readlink -f "$1")
OUT=$(readlink -f "$2")
KSTRING=${3:-Star 5.4.274 Kernel}
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

[ -f "$IMAGE" ] || { echo "no such Image: $IMAGE" >&2; exit 1; }

STAGE=$(mktemp -d "$HERE/.ak3.XXXXXX")
trap 'rm -rf "$STAGE"' EXIT

cp -a "$HERE/ak3/anykernel.sh" "$HERE/ak3/LICENSE" "$HERE/ak3/README.md" \
      "$HERE/ak3/tools" "$HERE/ak3/META-INF" "$STAGE/"
cp -f "$IMAGE" "$STAGE/Image"
sed -i "s|^kernel.string=.*|kernel.string=$KSTRING|" "$STAGE/anykernel.sh"
chmod 755 "$STAGE/META-INF/com/google/android/update-binary" "$STAGE"/tools/*

rm -f "$OUT"
( cd "$STAGE" && zip -qr -9 "$OUT" . )
echo "built $OUT $(stat -c%s "$OUT")"
echo "sha256 $(sha256sum "$OUT" | cut -d' ' -f1)"
