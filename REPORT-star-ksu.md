# Star 5.4.274 + KernelSU 构建报告

## 结论

内核基于真实 Linux 5.4.274 源码，已内置 KernelSU，配置按 ikun 5.4.302 的 `build_venus.sh` 对齐。**仅替换 boot.img 内的内核**，ramdisk 字节未改动。

## 产物

| 文件 | 大小 | SHA-256 |
|---|---|---|
| `Image-5.4.274-star-ksu` | 46,973,440 | `467d30181c6f5d1dd1ab6cd3f8bc47c6b075b29863e2ed53074adace2f152dc2` |
| `boot-5.4.274-star-ksu.img` | 68,427,776 | `934c6185b0c5bfbd86a115d4175b9522479dcdaad1b4f0cc6fcc0068b5f44e3d` |
| `Star-5.4.274-star-ksu-AnyKernel3.zip` | 23,849,535 | `3f4b6660144e05a3d029fc2f15d8be7f3ec9d8f3f0ca6c03bb832c0bd91f977b` |
| `config-5.4.274-star-ksu.txt` | 190,451 | `00421d6b92f0cde94205e15ee36a4dfd209885cca6b81804a4ff065a56555ca7` |

banner：`Linux version 5.4.274-VK-Y+ (root@...) (Android (6443078 based on r383902) clang version 11.0.1, LLD 11.0.1) #3 SMP PREEMPT Thu Oct 29 15:38:24 CST 2026`

vermagic：`5.4.274-VK-Y+ SMP preempt mod_unload modversions aarch64`

## boot.img 校验

- `header_version=3`、`header_size=1580`、`os_version=0x1a000194` 与官方一致
- ramdisk `sha256=cf355784...d2928`，与 OS2.0.7.0 原厂 **字节完全相同**
- 内核载荷 `sha256=467d3018...52dc2`，与发布的 Image 一致
- zip 内 `Image` sha256 与发布 Image 一致

## KernelSU

- 源码：上游 `ReSukiSU/ReSukiSU` `d5e9e02`（非 hushangda fork——那个要求 BakaSU SELinux 桥，ikun 的树里没有）
- `CONFIG_KSU=y`、`KSU_MANUAL_HOOK=y`、`KSU_MULTI_MANAGER_SUPPORT=y`
- 手动 hook：`ksu_handle_execveat`(fs/exec.c)、`ksu_handle_faccessat`(fs/open.c)、`ksu_handle_stat`+`newfstat_ret`+`fstat64_ret`(fs/stat.c)、`ksu_handle_sys_reboot`(kernel/reboot.c)
- 自动 LSM hook：`KSU_MANUAL_HOOK_AUTO_SETUID_HOOK` / `_INITRC_HOOK` / `_INPUT_HOOK` 均为 `y`
- 全套 hook 检查（`manual_hook_check.mk`）通过，不兼容 hook 全部为 0

## 与 ikun 5.4.302 的配置差异

`star_defconfig` 与 ikun 的 `sha256=664ae861...a11ce` 字节相同。在此基础上按 `build_venus.sh` 做了 `scripts/config` 补丁。

| | 启用符号 | 仅我有 | 仅他有 |
|---|---|---|---|
| 本版 | 2056 | 59 | 37 |
| ikun 302 | 2034 | — | — |

对齐前是 116/71，现在 59/37。

**37 个「仅 ikun 有」的分类：**

| 类别 | 数量 | 说明 |
|---|---|---|
| `KSU_SUSFS*` | 12 | 本版未启用，见下节 |
| LZ4K / LZ4KD / LZ4P / ZSTDN | 8 | 302 才有的压缩算法，274 树里无源码 |
| 302 独有 | 7 | `DM_USER`、`ZRAM_MULTI_COMP`、`SURFACE_PLATFORMS`、`OPLUS_FEATURE_HANS`、`PROC_MEM_ALWAYS_FORCE`、`ANDROID_VENDOR_FREEZER_COMPAT`、`ARM64_ERRATUM_3194386` |
| 编译器/版本内部量 | 7 | `CC_HAS_*`、`HAVE_KCSAN_COMPILER`、`POLLY_CLANG`、`STACKPROTECTOR_PER_TASK`、`TASKS_TRACE_RCU`、`HAVE_FUNCTION_GRAPH_TRACER` |

前 27 项在 274 源码里不存在，加不了。后 7 项由 clang 11 / 5.4.274 自身决定，不可设置。

**59 个「仅我有」的分类：** 27 个 ARM64/CAVIUM/QCOM CPU 勘误与硬件缓解（274 的 ACK 默认值，不该关）、9 个加固项（`SLAB_FREELIST_*`、`RODATA_FULL`、`UNMAP_KERNEL_AT_EL0`）、`MODVERSIONS`（保留，与官方一致）、`KPROBES*`（官方有）、`KSU_MANUAL_HOOK*`（4 个，ikun 走 SUSFS inline hook 所以没有）、其余为调度/网络默认项。

**已按 ikun 关闭的本机冗余：** `MEDIA_TUNER_*`（37 个）、`CORESIGHT_*`/`STM`（17 个）、`KFENCE`、`RCU_TRACE`、`PANIC_ON_OOPS`、`SLUB_DEBUG`。Image 里 `MEDIA_TUNER`/`coresight` 字符串计数均为 0。

## SuSFS 为什么没进

ikun 的 SuSFS 是 **v2.1.0**（`fs/susfs.c` 1493 行、`susfs.h` 241 行、`susfs_def.h` 171 行），公开的 `susfs4ksu` 5.4 分支只到 **v1.5.5**（916 / 186 / 62 行）。

ReSukiSU 的 `supercall/dispatch.c` 依赖 27 个 v2.x 才有的函数（`susfs_add_sus_map`、`susfs_add_sus_path_loop`、`susfs_set_hide_sus_mnts_for_non_su_procs`、`susfs_set_avc_log_spoofing`、`susfs_get_enabled_features`、`susfs_show_variant` 等）和 4 个 v2.x 才有的 `CMD_SUSFS_*` 常量。ikun 是通过整体搬运 hushangda 那棵 302 树拿到的，上游没有独立的 5.4 v2.1.0 patch。

强行拼接 v1.5.5 的文件和 v2.x 的调用会导致 22 个被 `50_add_susfs_in_kernel-5.4.patch` 改过的内核文件里出现 23 个未定义符号（`susfs_task_state`、`susfs_mnt_id_backup`、`susfs_sus_ino_for_filldir64`、`susfs_is_current_ksu_domain` 等）。所以本版**明确关闭** `CONFIG_KSU_SUSFS`，保证 KSU 可用、能开机。需要 SuSFS 的话得单独移植 v2.1.0，那是另一件事。

## 仍未验证 / 已知限制

1. **未真机验证。** 没有刷入过，开机、触摸、相机、指纹、基带全部未测。
2. **vendor_boot 里的 43 个 .ko 无法加载。** `module_layout` CRC 官方是 `0x1e5b7ab7`/`0x894a26ae`，本版是 `0xbb861412`；vermagic 也不一致（官方 `5.4.274-qgki-g4dfe63e0666f`，本版 `5.4.274-VK-Y+`）。原因是 genksyms 对结构体文本做哈希，KABI reserve 槽位不同就必然不同。ikun 和 MiYume 的 302 也是同样取舍（`do.modules=0`、全部内置）。本版 0 个 `.ko`，所有驱动编译进内核，功能上不依赖那 43 个模块。
3. **`LOCALVERSION` 是 `-VK-Y`**（沿用树里 `star_defconfig` 的写法），所以 banner 不是 `-qgki`。这不影响任何功能，但如果 OTA 或某些 vendor 服务按 vermagic 前缀判断可能有影响——未验证。

## 刷入方式

已在原厂 boot 上验证：ramdisk 未被替换，cmdline / os_version / DTB 全部沿用。

```bash
# 先备份
adb shell su -c 'dd if=/dev/block/by-name/boot_a of=/sdcard/boot_stock.img'

# 方式一：临时启动，不动分区（重启即恢复）
fastboot boot boot-5.4.274-star-ksu.img

# 方式二：TWRP / 内核管理器刷 AnyKernel3 zip
# 会自动识别当前 slot
```

失败的话 `fastboot flash boot boot_stock.img` 回退。


