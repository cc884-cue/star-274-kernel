# Star 5.4.274 构建成功与交付报告（路线 1）

生成时间：2026-10-28
工作树：`/workspace/los-21`，分支 `star-274`，HEAD `c79add6444da`
基线：LineageOS `lineage-21`（5.4.268，`81f65f1f117e`）+ ACK `android11-5.4-lts` 提交 `46cf3302`（Merge 5.4.274）

---

## 0. 先回答“是不是中断了”

不是中断。上一轮是**构建失败**，不是进程被杀：

- 第 2 次构建修掉了 `qcacld` 的重复符号后，链接阶段又报 3 个未定义符号：
  ```
  ld.lld: error: undefined symbol: mi_disp_register_client
  ld.lld: error: undefined symbol: mi_disp_unregister_client
  ld.lld: error: undefined symbol: dsi_display_primary_request_fod_hbm
  ```
- 根因：这三个符号在 `techpack/display/msm/` 里，而 LineageOS 的
  `techpack/display/config/lahainadisp.conf` 写的是 `export CONFIG_DISPLAY_BUILD=m`，
  即显示驱动被编成 `msm_drm.ko` 模块；我们把触摸/充电/热控全部内置后，内置代码引用模块符号，链接必然失败。
- 对照 302 两个项目：它们的 `lahainadisp.conf` / `gki_lahainadisp.conf` 写的是
  `export CONFIG_DISPLAY_BUILD=y`，显示驱动**内置**。这正是 302 能做到“全内置、零模块”的关键。
- 修复：把 `lahainadisp.conf` 与 `gki_lahainadisp.conf` 的 `CONFIG_DISPLAY_BUILD` 改为 `y`，重新构建 → **成功**。

---

## 1. 构建结果

| 项目 | 值 |
|---|---|
| 内核版本 | `5.4.274`（Makefile `VERSION=5 PATCHLEVEL=4 SUBLEVEL=274`） |
| banner | `5.4.274-qgki-gc79add6444da-dirty` |
| vermagic | `5.4.274-qgki-gc79add6444da-dirty SMP preempt mod_unload modversions aarch64` |
| Image 大小 | 52,085,248 字节 |
| Image SHA-256 | `b299ccc5f61fbed26d86487d2899740b5b70453e942aea336192c2259963d415` |
| ARM64 头 | magic `0x644d5241`，text_offset `0x80000`，image_size 58,081,280，flags `0xa` |
| 模块数 | **0**（`find -name '*.ko'` = 0） |
| 配置符号数 | 2,056 |
| 构建日志 | `/workspace/star-274-verify/build-los.log`（累计 7,722 行；第 3 段 176 行，0 error，3 条 MODPOST 警告） |

构建命令：
```bash
cd /workspace/los-21
export PATH=/workspace/mi11ultra-kernel/toolchain/clang-r383902/bin:$PATH
make -j8 ARCH=arm64 O=/workspace/star-274-verify/los-out \
  CC=clang LD=ld.lld HOSTCC=gcc \
  CROSS_COMPILE=aarch64-linux-gnu- CLANG_TRIPLE=aarch64-linux-gnu- Image
```

---

## 2. 为让“全内置”链接通过所做的源码改动（共 10 个文件）

| # | 文件 | 改动 | 原因 |
|---|---|---|---|
| 1 | `drivers/staging/qcacld-3.0/core/hdd/src/wlan_hdd_main.c` | `wlan_hdd_state_ctrl_param_create` 加 `__maybe_unused` | 内置编译时该函数只在 `#ifdef MODULE` 分支被调用，`-Werror` 报未使用 |
| 2 | `drivers/staging/qca-wifi-host-cmn/utils/nlink/src/wlan_nlink_srv.c` | `nl80211hdr_put` → `cld80211hdr_put`（3 处） | 与 `net/wireless/nl80211.c` 同名符号冲突 |
| 3 | `drivers/staging/qca-wifi-host-cmn/utils/nlink/inc/wlan_nlink_srv.h` | 同上（3 处） | 同上 |
| 4–10 | `drivers/staging/qcacld-3.0/components/ipa/{core,dispatcher}/**`、`core/hdd/src/wlan_hdd_driver_ops.c` | `ipa_is_ready` → `wlan_ipa_is_ready`（35 处） | 与 `drivers/platform/msm/ipa_fmwk/ipa_fmwk.c` 同名符号冲突 |
| 11 | `techpack/display/config/lahainadisp.conf` | `CONFIG_DISPLAY_BUILD=m` → `y` | 显示驱动内置，提供 `mi_disp_*` / `dsi_display_primary_request_fod_hbm` |
| 12 | `techpack/display/config/gki_lahainadisp.conf` | 同上 | 同上（非 QGKI 分支） |

> 说明：`nl80211hdr_put` 与 `ipa_is_ready` 的改名只影响 qcacld 内部符号，不改变对外接口；
> 且 stock 内核里 qcacld 相关字符串为 0，说明原厂本来就没把 qcacld 编进内核，这两处冲突是 LineageOS 树把 staging WLAN 打开后才出现的。

---

## 3. 产物

| 文件 | 大小 | SHA-256 |
|---|---|---|
| `/workspace/star-274-verify/los-out/arch/arm64/boot/Image` | 52,085,248 | `b299ccc5f61fbed26d86487d2899740b5b70453e942aea336192c2259963d415` |
| `/workspace/star-274-verify/boot-274-newkernel.img` | 73,539,584 | `6269224b7608d0e9fc72c62ca19c80ec1e545814ac4a3424f0c3ce6a6f808bdd` |
| `/workspace/star-274-verify/Star-5.4.274-star-kernelonly-AnyKernel3.zip` | 25,680,832 | `964f39a3858cce680f3e7bb154763f2118f1cc0c27211d70518d1dcfa9e8c6cd` |
| `/workspace/star-274-verify/star-274.config` | 191,294 | `474cbe0137bc7e0007dc86dddf6f88430bb8a16f75a7a8a53528fd753c876f46` |

### 3.1 `boot-274-newkernel.img` 的构造与校验

以 OS2.0.7.0 原厂 `boot.img` 为底，只替换 kernel 段：

- 原 `kernel_size` 51,161,600 → 新 52,085,248（+923,648 字节）
- `ramdisk_size` 21,446,361 **不变**
- `os_version` `0x1a000194` **不变**
- `header_version` 3、`header_size` 1580 **不变**
- 校验：新镜像内 ramdisk 与 stock **逐字节相同**，sha256 `cf3557840e6837fc…`
- 新镜像内 kernel 与 `Image` **逐字节相同**

### 3.2 AnyKernel3 包内容（最小集）

```
Image                                  52,085,248
anykernel.sh                                  983
META-INF/com/google/android/update-binary   19,948
META-INF/com/google/android/updater-script
tools/{ak3-core.sh,busybox,magiskboot,fec,httools_static,lptools_static,magiskpolicy,snapshotupdater_static}
LICENSE
```

`anykernel.sh` 关键项：
```
do.devicecheck=1     device.name1=star
do.modules=0         do.systemless=0     do.cleanup=1
BLOCK=boot           IS_SLOT_DEVICE=auto
RAMDISK_COMPRESSION=auto   PATCH_VBMETA_FLAG=auto
split_boot; flash_boot;      # 保留原 ramdisk，只换 kernel
```
- 只写 `boot` 分区；`write_boot` 里的 `vendor_dlkm`/`system_dlkm`/`dtbo` 分支因包内无对应镜像而自动跳过。
- 槽位由 `ro.boot.slot_suffix` 自动判定，不写死 `_a`。
- 不安装 Magisk/KSU，不写 system，不动 vbmeta。

---

## 4. 兼容性核对

### 4.1 ABI 关键项（与 stock 一致）

| 项 | 本内核 | stock |
|---|---|---|
| 页大小 | 4K | 4K |
| VA_BITS | 39 | 39 |
| PA_BITS | 48 | 48 |
| RANDOMIZE_BASE | y | y |
| ARM64_MODULE_PLTS | y | y |
| RELOCATABLE | y | y |
| LTO / THINLTO / CFI_CLANG | y / y / y | y / y / y |
| SHADOW_CALL_STACK | y | y |
| CMDLINE | `ramoops_memreserve=4M` | 同 |
| STATIC_USERMODEHELPER_PATH | `/system/bin/micd` | 同 |
| DEVTMPFS | n | n |

### 4.2 配置差异（stock 启用、本内核未启用：68 项）

其中 34 项是 `MEDIA_TUNER_*`（电视调谐器，与手机无关），其余主要是小米私有件：

`MIHW`、`MILLET`、`MIGT`、`OEM_KERNEL`、`QGKI_SYSTEM`、`PASSTHROUGH_SYSTEM`、`SF_BINDER`、
`UFSGKI`、`UFS_WB`、`MI_UFS_FFU`、`MI_RECLAIM`、`MIUI_ZRAM_MEMORY_TRACKING`、`XLOGCHAR`、
`DEBUG_POWER_MI`、`CLD`、`F2FS_CP_OPT`、`QCOM_MINIDUMP_ENCRYPT`、`QTI_TZ_LOG`、
`TOUCHSCREEN_ST_FTS_V521_SPI_K2`、`MI_CNSS_STATISTIC`、`MI_MEMORY_SYSFS`、
`FINGERPRINT_SET_VREG_CONTROL`、`FASTBOOT_CMD_CTRL_UART`、`DEBUG_POLICY_STATUS`、
`GPIO_TESTING_MODE`、`I3C_MASTER_MSM_GENI`、`PERF_CRITICAL_RT_TASK`、`PACKAGE_RUNTIME_INFO`、
`BOOTUP_RECLAIM`、`CAM_RECLAIM`、`MTD_*`（11 项）。

**没有一项是启动必需的**：UFS、UFS PHY、RPMh、regulator、clock、pinctrl、SMMU、PMIC、USB、热控全部 `=y`。

### 4.3 DTB 兼容性（stock dtbo 143 + vendor_dtb 297，去重 433 个 compatible）

用“字符串是否出现在 Image 中”做覆盖比对：

- 本内核缺失 164 个，其中 **stock 内核同样缺失 161 个**（相机/音频/传感器等由 vendor_dlkm 模块或用户态负责）
- **真正回退只有 3 个**：
  - `modem,md-testing-mode`（小米 modem 测试模式，调试用）
  - `qcom,geni-i3c`（I3C 主控，本内核 `I3C=n`）
  - `qcom,tz-log`（TZ 日志，调试用）

### 4.4 原厂模块能否加载：**不能**

| 项 | 值 |
|---|---|
| 本内核 `module_layout` CRC | `0x7f3c5d5e`（2134662494） |
| stock 43 个模块 `module_layout` CRC | `0x1e5b7ab7`（509311671）；`msm_drm.ko` 为 `0x894a26ae` |
| 符号 CRC 比对 | 2,336 个引用中 941 相同、1,393 不同、2 缺失（40.3%） |

结论：`vendor_boot` 里的 43 个 `.ko`（以及 `vendor_dlkm` 里的模块）在加载时会因
`disagrees about version of symbol module_layout` 被拒绝。

这不是本次改动的失误，而是“用非小米源码树编译”的必然结果——genksyms 对结构体定义文本做哈希，
小米在原厂树里改过 `struct module` 等结构，CRC 无法对上。**302 的两个内核也是同样情况**，
它们靠“所有驱动内置”绕开：模块加载失败无所谓，因为功能已经在核心里。

本内核同样采用该策略：0 模块，43 个原厂模块对应的驱动全部 `=y` 内置（已逐个核对）。

---

## 5. 必须说清楚的风险

1. **未上机验证**。以上全部是静态核对，没有任何一次真机启动证据。不要把它当成“可启动”的承诺。
2. **原厂模块全部失效**。若某个功能只存在于 `vendor_dlkm` 模块里而内核没有内置对应驱动，该功能会丢失。
   已确认启动链路（存储/时钟/电源/引脚/中断）全部内置。
3. **小米私有件缺失**：`MIHW`、`MILLET`、`MIGT` 等不在 LineageOS 树中。`/proc/millet` 不存在，
   部分 MIUI 系统服务可能报错（通常不致命）。
4. **相机**：LineageOS 树没有 `techpack/camera_star`，star 相机大概率不可用。
5. **AVB**：`boot.img` 未重新签名。要求 BL 已解锁且校验已关闭（与 302 包一致）。
6. **`-dirty` 后缀**：vermagic 带 `-dirty`，因为工作树有未提交改动。对模块加载无影响（有 `__versions` 时前缀被忽略）。

---

## 6. 建议的验证顺序（由你操作）

1. 先备份当前 `boot` 分区（`dd if=/dev/block/by-name/boot$(getprop ro.boot.slot_suffix) of=/sdcard/boot-backup.img`）。
2. 优先用 `boot-274-newkernel.img` 走 fastboot 单次启动验证：
   `fastboot boot boot-274-newkernel.img`（不落盘，失败重启即恢复）。
3. 若 `fastboot boot` 不支持（部分小米机型限制），再刷 AnyKernel3 zip。
4. 关注点：能否进系统、触摸、显示、指纹、Wi-Fi、充电、重启。
5. 出问题就 `fastboot flash boot boot-backup.img` 回滚。

---

## 7. 结论

- 5.4.274 内核**已构建成功**，版本号真实（`SUBLEVEL=274`，非改名）。
- “仅替换 boot 内 kernel”在**镜像层面成立**：ramdisk/cmdline/DTB/DTBO/vendor_boot 全部原样保留。
- “保留原厂模块可用”**不成立**，且无法通过本路线达成；本内核以“全内置”替代，与 302 做法一致。
- 是否可启动、功能是否完整，**必须真机验证**。
