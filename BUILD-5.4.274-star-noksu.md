# Star 5.4.274 no-KernelSU source snapshot

This repository records the exact source-tree state used for the bootable-but-slow `v5.4.274-noksu` build for Xiaomi 11 Ultra (`star`).

## Build result

- Linux version: `5.4.274-VK-Y+`
- Device: Xiaomi 11 Ultra / `star`
- Compiler: Android clang r383902, clang/LLD 11.0.1
- Output: `arch/arm64/boot/Image`
- Image SHA-256: `b1fb568c8ee9dfe606a68fbaa78a4f34db99ff9b9d5ef16a6c7d1804df15c1ef`
- Image size: 46,907,904 bytes
- `CONFIG_KSU` is disabled; the resulting Image contains zero `ksu_`, `KernelSU`, and `susfs` strings
- Config: 1,938 `=y`, 0 `=m`; all drivers are built in

## Source route

The base is the Xiaomi SM8350 Venus 5.4.285 snapshot. ACK stable changes 5.4.275 through 5.4.285 were reverse-applied where compatible, leaving the kernel Makefile at the real `5.4.274` sublevel. Xiaomi vendor code and `techpack/camera_star` were retained.

The tree contains the integration patches used while producing the KSU and no-KSU variants, but KSU/SuSFS/KPM are disabled in the no-KSU build configuration. Do not enable those options without rebuilding and reviewing the hook integration.

## Kernel-only packaging

The published boot image replaces only the kernel payload. The stock OS2.0.7.0 boot ramdisk is byte-identical and all other partitions remain untouched.

- Release: https://github.com/cc884-cue/star-274-kernel/releases/tag/v5.4.274-noksu
- Source branch: `star-5.4.274-noksu`

## Device test status

This build has now booted to the Xiaomi logo and produced vibration, but did not reach Android in the first test and had a long startup. Further boot-time diagnosis is intentionally deferred to the next session.
