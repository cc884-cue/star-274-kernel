## Linux 5.4.274 for Xiaomi Mi 11 Ultra (star)

Real 5.4.274, built to replace **only the kernel inside `boot.img`**. Original ramdisk, cmdline, DTB/DTBO, `vendor_boot` and all other partitions untouched.

Target ROM: **OS2.0.7.0.UKACNXM** (Android 14 / SDK 34), stock kernel `5.4.274-qgki-g4dfe63e0666f`.

> **All files are for `star` (Mi 11 Ultra).** The `-star` suffix is the device.
> An earlier revision of this release used `-venus` in the filenames — that was the *source tree* name
> (`android_kernel_xiaomi_sm8350_venus`, the tree ikun and MiYume build from), not the target device.
> Renamed for clarity. The bytes are unchanged.

---

### Which one do I want?

**`star`** — has all the Xiaomi private code (`MIHW`, `MILLET`, `OEM_KERNEL`, `MI_RECLAIM`, `CAM_RECLAIM`, `techpack/camera_star`). This is how ikun and MiYume build their 302 kernels, just at 274. **Start here.**

**`los`** — LineageOS tree, no Xiaomi private code. Camera and some vendor features will not work. Kept for comparison.

### Why the `star` build is really for star

- `CONFIG_MACH_XIAOMI_STAR=y`, `CONFIG_MACH_XIAOMI_SM8350=y`, `CONFIG_ARCH_LAHAINA=y`
- **No** `MACH_XIAOMI_VENUS` / `MARS` / `ODIN` / `CETUS` / `HAYDEN` in the config
- `techpack/camera_star`: **135 objects compiled** — `techpack/camera_venus`: **0**
- Image strings: `camera_star` 7, `millet` 59, `aw8697` 141, `goodix` 62, `bq2597x` 17, `stmvl53l5` 37
- AnyKernel3 installer: `device.name1=star`, `do.devicecheck=1`

---

### Files

| File | Size | SHA-256 |
|---|---|---|
| `boot-5.4.274-star.img` | 72,105,984 | `1aa981e5a22d968de99ea53453cd25733e9cab6d760fcbc5c197d5b0a979b35d` |
| `Star-5.4.274-star-AnyKernel3.zip` | 24,207,729 | `1e8e3175b4939d9ad0865e76432b9dfa8c3ade02e254366ae58e45be25e52b59` |
| `Image-5.4.274-star` | 50,651,648 | `6bcea5ac27c7c3f05d960ee6513c583ff33f4ca965d2a4a1de2f6adeae0a8a37` |
| `config-5.4.274-star.txt` | 189,240 | `87c38d159e3575f5a8f8484919e2b6b38af9298e24a7c4a529e4f5eb782f5d7a` |
| `boot-5.4.274-los.img` | 73,539,584 | `6269224b7608d0e9fc72c62ca19c80ec1e545814ac4a3424f0c3ce6a6f808bdd` |
| `Star-5.4.274-los-AnyKernel3.zip` | 25,680,832 | `964f39a3858cce680f3e7bb154763f2118f1cc0c27211d70518d1dcfa9e8c6cd` |
| `Image-5.4.274-los` | 52,085,248 | `b299ccc5f61fbed26d86487d2899740b5b70453e942aea336192c2259963d415` |
| `config-5.4.274-los.txt` | 191,294 | `474cbe0137bc7e0007dc86dddf6f88430bb8a16f75a7a8a53528fd753c876f46` |

---

### Install

**Try it without writing anything first:**

```bash
fastboot boot boot-5.4.274-star.img
```

Nothing is written to the device. If it fails, reboot and you are back on stock.

**Back up, then flash:**

```bash
adb shell su -c 'dd if=/dev/block/by-name/boot$(getprop ro.boot.slot_suffix) of=/sdcard/boot-backup.img'
fastboot flash boot boot-5.4.274-star.img
```

**Or flash the AnyKernel3 zip** in TWRP / KernelSU / SukiSU. It splits your current boot, swaps only the kernel, and repacks — ramdisk and cmdline preserved. Device check is on (`device.name1=star`).

**Rollback:** `fastboot flash boot boot-backup.img`

---

### Verified

- Ramdisk in `boot-5.4.274-star.img` is **byte-identical** to the stock OS2.0.7.0 ramdisk
- `os_version 0x1a000194` and `header_version 3` preserved
- Kernel partition usage **decreased**: 51,161,600 → 50,651,648 bytes
- Boot-critical drivers all built-in: UFS, UFS PHY, RPMH clock/regulator/pd, pinctrl-lahaina, SCM, SMMU, PDC, GCC, interconnect, charger, PIL, minidump, HW key manager, UFS crypto
- ABI identical to stock: 4K pages, VA_BITS 39, PA_BITS 48, RANDOMIZE_BASE, RELOCATABLE
- `millet` strings: **59** — same count as stock, ikun, and MiYume
- Star's DTB compatibles all have a driver in the tree: `xiaomi-touch`, `ir-spi-led`, `novatek,NVT-ts`, `zinitix,bt541_ts_device`, `goodix,fingerprint`, `awinic,aw8697_haptic`, `st,stmvl53l5`, `cy,cyttsp5_i2c_adapter`, `focaltech,fts_ts`, `qcom,dsi-display`, `qcom,cam-sensor`

---

### Known limitations

1. **Not device-tested.** All verification is static. Use `fastboot boot` first.
2. **The 43 stock vendor modules will not load** (`module_layout` CRC `0xb216eb53` vs stock `0x1e5b7ab7`). Every driver is built into the Image instead, so nothing is needed from `vendor_boot`. Same trade-off ikun and MiYume make.
3. **The source tree is not pure 274.** 28 files stay at 285 (binder, f2fs, dwc3, erofs, cpucaps) — reverse-applying stable patches there yields half-274/half-285 states that do not compile. Version string and the bulk of the tree are genuinely 274.
4. **LTO and CFI are off**, matching the venus `star_defconfig` default. ikun turns them on.
5. **AVB not re-signed.** Bootloader must be unlocked.
6. 22 stock config symbols missing (`QGKI_SYSTEM`, `SF_BINDER`, `UFSGKI`, `MIGT`, `XLOGCHAR`, …). They exist only in Xiaomi's internal tree — ikun and MiYume lack them too.

---

Toolchain: Android `r383902` / Clang 11.0.1 (stock used `r383902b1` / 11.0.2).
Full build logs and conflict resolution in `REPORT-star.md` and `REPORT-los.md`.
