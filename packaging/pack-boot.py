#!/usr/bin/env python3
"""Pack a compiled arm64 Image into a boot.img that keeps the stock ramdisk byte-for-byte.

`magiskboot repack` recompresses the ramdisk (gzip), so the result is NOT byte-identical
to stock even though the kernel payload is right. On stock HyperOS/MIUI that difference is
a needless variable, and the packing step can no longer be verified against a known-good
boot.img. This script instead rewrites header.kernel_size and re-lays the file:

    header page (v3) | Image (page aligned) | stock ramdisk blob verbatim | zero pad

usage: pack-boot.py <stock-boot.img> <Image> <out-boot.img> [--size 201326592]
"""
import argparse, hashlib, struct, sys

PAGE = 4096
MAGIC = b"ANDROID!"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("stock")
    ap.add_argument("image")
    ap.add_argument("out")
    ap.add_argument("--size", type=int, default=201326592)
    a = ap.parse_args()

    stock = open(a.stock, "rb").read()
    if stock[:8] != MAGIC:
        sys.exit("not an Android boot image")
    kernel_size, ramdisk_size, os_version, header_size, hv = struct.unpack_from("<IIIII", stock, 8)
    header_version, = struct.unpack_from("<I", stock, 40)
    if header_version != 3:
        sys.exit(f"header_version {header_version}: this layout is v3-only")

    img = open(a.image, "rb").read()

    hdr = bytearray(stock[:PAGE])
    struct.pack_into("<I", hdr, 8, len(img))
    stock_rd_off = PAGE + ((kernel_size + PAGE - 1) // PAGE) * PAGE
    ramdisk = stock[stock_rd_off:stock_rd_off + ramdisk_size]
    if len(ramdisk) != ramdisk_size:
        sys.exit("stock ramdisk truncated")

    body = bytes(hdr) + img + b"\0" * ((-len(img)) % PAGE) + ramdisk
    body += b"\0" * ((PAGE - len(body) % PAGE) % PAGE)
    if len(body) > a.size:
        sys.exit(f"image {len(body)} > partition {a.size}")
    body += b"\0" * (a.size - len(body))
    open(a.out, "wb").write(body)
    print(f"{a.out} {len(body)}")
    print(f"sha256 {hashlib.sha256(body).hexdigest()}")


if __name__ == "__main__":
    main()
