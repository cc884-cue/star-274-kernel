# Star 5.4.274 Kernel — Xiaomi Mi 11 Ultra (star / SM8350)

Real Linux **5.4.274** kernels for the Xiaomi Mi 11 Ultra, built to replace **only the kernel inside `boot.img`**.
The original ramdisk, cmdline, DTB/DTBO, `vendor_boot`, and every other partition stay untouched.

Target ROM: **OS2.0.7.0.UKACNXM** (Android 14 / SDK 34), stock kernel `5.4.274-qgki-g4dfe63e0666f`.

---

## Two builds

| | **venus** (recommended) | **los** |
|---|---|---|
| Source | venus 5.4.285 snapshot, ACK stable 275..285 reverse-applied | LineageOS `lineage-21` (5.4.268) merged with ACK `46cf3302` |
| Xiaomi private code | ✅ `MIHW` `MILLET` `OEM_KERNEL` `MI_RECLAIM` `CAM_RECLAIM` `MACH_XIAOMI_STAR` `techpack/camera_star` | ❌ none |
| `millet` strings | 59 (= stock = ikun = MiYume) | 0 |
| Image size | 50,651,648 | 52,085,248 |
| Modules | 0 (all built-in) | 0 (all built-in) |
| LTO / CFI | off | off |

**Use `venus` unless you have a reason not to.** It is the closest thing to how ikun / MiYume build their 302 kernels, just at 274.

---

## Downloads

| File | What it is |
|---|---|
| `boot-5.4.274-venus.img` | Prebuilt boot image. Flash directly, or `fastboot boot` it first. |
| `Star-5.4.274-venus-AnyKernel3.zip` | Flashable zip (TWRP / KernelSU / SukiSU). Repacks your existing boot. |
| `Image-5.4.274-venus` | Raw arm64 kernel. For manual repacking. |
| `config-5.4.274-venus.txt` | Full kernel config (2,083 symbols, 0 modules). |
| `SHA256SUMS.txt` | Verify everything after download. |

`los` variants are the same four files with `-los` in the name.

---

## Install

### Option A — try without writing (safest)

```bash
fastboot boot boot-5.4.274-venus.img
```

Nothing is written. If it fails, just reboot and you are back on stock.

### Option B — flash the boot image

```bash
# back up first
adb shell su -c 'dd if=/dev/block/by-name/boot$(getprop ro.boot.slot_suffix) of=/sdcard/boot-backup.img'

fastboot flash boot boot-5.4.274-venus.img
fastboot reboot
```

### Option C — AnyKernel3 zip

Flash `Star-5.4.274-venus-AnyKernel3.zip` in TWRP or a KernelSU/SukiSU manager.
The installer splits your current boot, swaps only the kernel, and repacks — ramdisk and cmdline are preserved.

Device check is enabled (`device.name1=star`), so it refuses to flash on other devices.

### Rollback

```bash
fastboot flash boot boot-backup.img
```

---

## Verified before shipping

- `boot-5.4.274-venus.img` ramdisk is **byte-identical** to the stock OS2.0.7.0 ramdisk (`sha256 cf355784…`)
- `os_version 0x1a000194` and `header_version 3` preserved
- Kernel partition usage **decreased**: 51,161,600 → 50,651,648 bytes
- Boot-critical drivers all built-in: `SCSI_UFS_QCOM` `PHY_QCOM_UFS_V4` `QCOM_CLK_RPMH` `QCOM_RPMH` `QCOM_RPMHPD` `PINCTRL_LAHAINA` `REGULATOR_RPMH` `QCOM_SCM` `ARM_SMMU` `QCOM_PDC` `MSM_GCC_LAHAINA` `INTERCONNECT_QCOM_LAHAINA` `QTI_BATTERY_CHARGER` `MSM_PIL` `QCOM_MEMORY_DUMP_V2` `QTI_HW_KEY_MANAGER` `SCSI_UFS_CRYPTO_QTI`
- ABI identical to stock: `ARM64_4K_PAGES` `ARM64_VA_BITS=39` `ARM64_PA_BITS=48` `RANDOMIZE_BASE` `RELOCATABLE`

---

## Known limitations

1. **Not device-tested.** Everything above is static verification. Boot it with `fastboot boot` first.
2. **The 43 stock vendor modules will not load.** `module_layout` CRC is `0xb216eb53` here vs `0x1e5b7ab7` stock — genksyms hashes struct text, and the KABI reserve slots differ. Every driver is built into the Image instead, so nothing is needed from `vendor_boot`. This is the same trade-off ikun and MiYume make.
3. **The venus tree is not pure 274.** 28 files stay at 285 (binder, f2fs, dwc3, erofs, cpucaps) because reverse-applying the stable patches there produces half-274/half-285 states that do not compile. The version string and the bulk of the tree are genuinely 274.
4. **LTO and CFI are off**, matching the venus `star_defconfig` default. ikun turns them on.
5. **AVB is not re-signed.** Bootloader must be unlocked.
6. 22 stock config symbols are missing (`QGKI_SYSTEM`, `SF_BINDER`, `UFSGKI`, `MIGT`, `XLOGCHAR`, …). They exist only in Xiaomi's internal tree — ikun and MiYume do not have them either.

---

## Build

```bash
export PATH=/path/to/clang-r383902/bin:$PATH
make -j8 ARCH=arm64 O=out \
  CC=clang LD=ld.lld HOSTCC=gcc \
  CROSS_COMPILE=aarch64-linux-gnu- CLANG_TRIPLE=aarch64-linux-gnu- Image
```

Toolchain: Android `r383902` / Clang 11.0.1 (stock used `r383902b1` / 11.0.2).

See `REPORT-venus.md` and `REPORT-los.md` for the full build logs, conflict resolution, and config diffs.
