# Star 5.4.274 无 KernelSU 版构建报告

## 结论

与 `v5.4.274-ksu` 同源同配置，**唯一区别是关掉了 KernelSU**。`CONFIG_KSU`、`CONFIG_KSU_MANUAL_HOOK*`、`CONFIG_KSU_MULTI_MANAGER_SUPPORT`、`CONFIG_KSU_SUSFS*`、`CONFIG_KPM` 全部 `is not set`。

Image 里 `ksu_` / `KernelSU` / `susfs` 字符串计数均为 **0**。

## 产物

| 文件 | 大小 | SHA-256 |
|---|---|---|
| `Image-5.4.274-star-noksu` | 46,907,904 | `b1fb568c8ee9dfe606a68fbaa78a4f34db99ff9b9d5ef16a6c7d1804df15c1ef` |
| `boot-5.4.274-star-noksu.img` | 68,362,240 | `00f83225b73e505c8c7999c8305c9028b9142a0e33c93995baff45c1cd1c3174` |
| `Star-5.4.274-star-noksu-AnyKernel3.zip` | 23,782,214 | `d20462cad5f61ea0af4bfa7c97325a1bd95b3f48a34585c5aaed46a4294c3033` |
| `config-5.4.274-star-noksu.txt` | 189,502 | `adb2dee18d8000edff905f7254ce2614644655d0caf6ad9dfaf4ce831b0fe1bf` |

banner：`Linux version 5.4.274-VK-Y+ (root@...) (Android (6443078 based on r383902) clang version 11.0.1, LLD 11.0.1) #1 SMP PREEMPT Thu Oct 29 16:14:27 CST 2026`

vermagic：`5.4.274-VK-Y+ SMP preempt mod_unload modversions aarch64`

## 与 KSU 版的差异

| | KSU 版 | 无 KSU 版 |
|---|---|---|
| Image | 46,973,440 | 46,907,904（−65,536） |
| `image_size` | 60,837,888 | 60,768,256 |
| 启用符号 | 1,944 | 1,938 |
| `=m` | 0 | 0 |
| `.ko` | 0 | 0 |

除 KSU 相关的 6 个符号外配置完全一致：`LTO=y`、`THINLTO=y`、`F2FS_FS_COMPRESSION=y`、`DEVTMPFS=y`、`DEVTMPFS_MOUNT=y`、`BPF_STREAM_PARSER=y`、`MODVERSIONS=y`、`SHADOW_CALL_STACK=y`、`KALLSYMS_ALL=y`。

## 共同点

- 源码：小米 SM8350 venus 树 5.4.285 快照，反向应用 ACK stable 275..285 → 真实 5.4.274
- `star_defconfig` 与 ikun 的字节相同（`sha256=664ae861...a11ce`）
- 小米私有代码完整：`millet` 字符串 59、`camera_star` 7、`mi_disp` 12
- 本机冗余已关：`MEDIA_TUNER` / `coresight` 字符串计数均为 0
- 0 个 `.ko`，所有驱动内置

## boot.img 校验

- `header_version=3`、`header_size=1580`、`os_version=0x1a000194` 与官方一致
- ramdisk `sha256=cf355784...d2928`，与 OS2.0.7.0 原厂**字节完全相同**
- 内核载荷 sha256 = 发布的 Image
- zip 内 `Image` sha256 与发布一致
- zip `anykernel.sh`：`do.devicecheck=1`、`device.name1=star`、`do.modules=0`、`BLOCK=boot`、`IS_SLOT_DEVICE=auto`

## 选哪个

- **要 root** → `v5.4.274-ksu`
- **不要 root / 只想换内核** → 本版。没有 KSU 的内核不会挂任何 syscall hook，行为和原厂最接近

两者都未真机验证。vendor_boot 里那 43 个 `.ko` 在两版里都加载不了（`module_layout` CRC 和 vermagic 对不上），所有驱动已内置。

## 刷入

```bash
# 备份
adb shell su -c 'dd if=/dev/block/by-name/boot_a of=/sdcard/boot_stock.img'
# 临时启动，不动分区
fastboot boot boot-5.4.274-star-noksu.img
```

或 TWRP 刷 AnyKernel3 zip。失败 `fastboot flash boot boot_stock.img` 回退。
