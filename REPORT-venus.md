# Star 5.4.274（venus 树路线）构建报告

生成时间：2026-10-28
工作树：`/workspace/venus-285`（名字保留，实际内容已是 5.4.274）
分支：detached HEAD → `11879619b`

---

## 0. 先纠正一个前提

**ikun 的上游不是 274，是 5.4.285。**

```
cabb4f45d  "Import current Venus kernel snapshot"   SUBLEVEL = 285   2026-05-03
89f841968  "Update Venus kernel to 5.4.302"         SUBLEVEL = 302   2026-05-04
```

ikun 的仓库只有 8 个提交，根提交 `cabb4f45d` 就是 venus 树的快照，版本 285；第二天直接跳到 302。
**这条血缘里从来没有 274。** 所以“找 ikun 的上游 274”这个动作本身不存在现成对象。

但 285 可以退到 274：ACK 的 stable 275..285 共 11 个补丁，反向应用即可。

---

## 1. 做法

```
venus 5.4.285 (cabb4f45d)
  └─ 反向应用 ACK stable 5.4.275 .. 5.4.285（11 个补丁，61,203 行，1,598 处文件改动）
       └─ 98.1% 干净应用，30 个文件冲突
            └─ 其中 28 个文件保留 285 原样（Xiaomi 改动区，强行回退会破坏 API）
                 └─ 2 个文件手工修（erofs / sched trace）
                      └─ 1 个文件手工修（dwc3 重复函数）
                           └─ Makefile SUBLEVEL = 274
```

### 1.1 反向应用统计

| 版本 | 补丁行数 | 涉及文件 | 累计冲突文件 |
|---|---|---|---|
| 5.4.285 | 21,432 | 437 | 15 |
| 5.4.284 | 4,051 | 120 | 16 |
| 5.4.283 | 5,094 | 137 | 19 |
| 5.4.282 | 8,669 | 251 | 21 |
| 5.4.281 | 1,322 | 45 | 21 |
| 5.4.280 | 2,442 | 73 | 21 |
| 5.4.279 | 5,831 | 159 | 25 |
| 5.4.278 | 5,792 | 189 | 28 |
| 5.4.277 | 672 | 18 | 28 |
| 5.4.276 | 2,862 | 80 | 28 |
| 5.4.275 | 3,036 | 89 | 30 |

### 1.2 保留 285 原样的 28 个文件

```
arch/arm64/include/asm/cpucaps.h        drivers/usb/dwc3/core.c
drivers/android/binder.c                drivers/usb/dwc3/core.h
drivers/clk/clk.c                       drivers/usb/gadget/function/f_fs.c
drivers/clocksource/timer-of.c          fs/ext4/xattr.c
drivers/hid/hid-ids.h                   fs/f2fs/{f2fs.h,file.c,inode.c,node.c,segment.c,xattr.c}
drivers/hid/hid-microsoft.c             include/trace/events/f2fs.h
drivers/hwtracing/coresight/...         kernel/bounds.c
drivers/input/touchscreen/fts_*/...     kernel/gen_kheaders.sh
drivers/net/phy/micrel.c                kernel/rcu/rcutorture.c
mm/swapfile.c                           net/ipv4/tcp_ipv4.c
net/qrtr/qrtr.c                         net/wireless/util.c
```

理由：这些文件是 Xiaomi 改动最集中的地方（binder 27 处 OEM 钩子、f2fs 小米调优、fts 触摸）。
反向补丁在这里只能部分应用，留下“半 274 半 285”的状态，编译必然报 API 不匹配。
保留 285 原样反而自洽。

### 1.3 手工修的 3 处

| 文件 | 问题 | 处理 |
|---|---|---|
| `fs/erofs/decompressor.c` | `z_erofs_lz4_decompress` 2 参 vs 3 参 | 恢复 285（`compress.h` 是 3 参） |
| `include/trace/events/sched.h` | 删了 `#include <linux/kthread.h>` 但保留 `kthread_work_func_t` 用法 | 恢复 285（全树 0 处引用该 tracepoint） |
| `drivers/usb/dwc3/gadget.c` | 反向补丁把函数加了两次 + 多一个 `}` | 删重复定义与多余大括号 |

### 1.4 KernelSU

`drivers/kernelsu` 是指向 `../KernelSU/kernel` 的符号链接，子模块未初始化导致 Kconfig 解析失败。
按既定范围（不加 KSU），放了桩 `KernelSU/kernel/Kconfig`（`config KSU` 默认 n）+ 空 Makefile。
`star_defconfig` 本身不含任何 KSU/SuSFS/KPM 项。

---

## 2. 构建结果

| 项 | 值 |
|---|---|
| 版本 | `5.4.274`（Makefile SUBLEVEL=274） |
| banner | `Linux version 5.4.274-VK-Y-g11879619 (root@046b262ac98b) (Android (6443078 based on r383902) clang version 11.0.1, LLD 11.0.1) #1 SMP PREEMPT Wed Oct 28 16:27:01 CST 2026` |
| vermagic | `5.4.274-VK-Y-g11879619 SMP preempt mod_unload modversions aarch64` |
| Image | 50,651,648 字节 |
| SHA-256 | `6bcea5ac27c7c3f05d960ee6513c583ff33f4ca965d2a4a1de2f6adeae0a8a37` |
| ARM64 头 | magic `0x644d5241`，text_offset `0x80000`，image_size 64,847,872，flags `0xa` |
| 模块数 | 0 |
| 配置 | 2,083 符号 / 1,968 `=y` / 0 `=m` |
| `module_layout` CRC | `0xb216eb53` |

构建命令：
```bash
cd /workspace/venus-285
export PATH=/workspace/mi11ultra-kernel/toolchain/clang-r383902/bin:$PATH
make -j8 ARCH=arm64 O=/workspace/venus-274-out \
  CC=clang LD=ld.lld HOSTCC=gcc \
  CROSS_COMPILE=aarch64-linux-gnu- CLANG_TRIPLE=aarch64-linux-gnu- Image
```

---

## 3. 和 LineageOS 路线的对比

| 项 | los-21 路线 | venus 路线 |
|---|---|---|
| 版本 | 5.4.274（真实合并） | 5.4.274（285 回退） |
| `MIHW` | ❌ | ✅ |
| `MILLET` | ❌ | ✅ |
| `OEM_KERNEL` | ❌ | ✅ |
| `MI_RECLAIM` / `CAM_RECLAIM` | ❌ | ✅ |
| `MACH_XIAOMI_STAR` | ❌ | ✅ |
| `techpack/camera_star` | ❌ | ✅ |
| `F2FS_CP_OPT` | ❌ | ✅ |
| `QTI_TZ_LOG` / `I3C_MASTER_MSM_GENI` | ❌ | ✅ |
| `millet` 字符串数 | 0 | **59**（= stock = ikun = MiYume） |
| stock 启用项缺失 | 68 | 139（多出的是 HISI/SUNXI/SHIMA/MTD/USB 触摸屏等 star 用不到的） |
| 模块数 | 0 | 0 |

**关键验证**：`millet` 字符串 59 个，与原厂内核、ikun、MiYume 完全一致。
说明 MILLET 框架（`/proc/millet` netlink IPC）已经完整编入。

### 3.1 仍然缺的（venus 树里也没有）

```
QGKI_SYSTEM  PASSTHROUGH_SYSTEM  SF_BINDER  UFSGKI  UFS_WB  MI_UFS_FFU
MIGT  MI_MEMORY_SYSFS  MI_CNSS_STATISTIC  MIUI_ZRAM_MEMORY_TRACKING
XLOGCHAR  DEBUG_POWER_MI  CLD  PACKAGE_RUNTIME_INFO  PERF_CRITICAL_RT_TASK
QCOM_MINIDUMP_ENCRYPT  BOOTUP_RECLAIM  DEBUG_POLICY_STATUS
FASTBOOT_CMD_CTRL_UART  FINGERPRINT_SET_VREG_CONTROL  GPIO_TESTING_MODE
TOUCHSCREEN_ST_FTS_V521_SPI_K2
```

这 22 项只存在于小米内部树，**ikun 和 MiYume 也没有**，它们照样能跑。
符合“ikun 没有的我们也不强求”。

### 3.2 与原厂配置的其它差异

| 项 | 本内核 | stock |
|---|---|---|
| `LOCALVERSION` | `-VK-Y` | `-qgki` |
| `CMDLINE` | `cgroup_disable=pressure` | `ramoops_memreserve=4M` |
| `LTO` / `THINLTO` / `CFI_CLANG` | 关 | 开 |
| `DEVTMPFS` | 关 | 关 |

`LTO`/`CFI` 关闭是 venus `star_defconfig` 的默认（ikun 是打开的）。
不影响启动，但少了 CFI 控制流完整性保护。需要的话可以单独开一轮。

---

## 4. 产物

| 文件 | 大小 | SHA-256 |
|---|---|---|
| `/workspace/venus-274-out/arch/arm64/boot/Image` | 50,651,648 | `6bcea5ac27c7c3f05d960ee6513c583ff33f4ca965d2a4a1de2f6adeae0a8a37` |
| `/workspace/star-274-verify/boot-274-venus.img` | 72,105,984 | `1aa981e5a22d968de99ea53453cd25733e9cab6d760fcbc5c197d5b0a979b35d` |
| `/workspace/star-274-verify/Star-5.4.274-star-venus-AnyKernel3.zip` | 24,207,729 | `1e8e3175b4939d9ad0865e76432b9dfa8c3ade02e254366ae58e45be25e52b59` |
| `/workspace/star-274-venus.config` | 189,240 | `87c38d159e3575f5a8f8484919e2b6b38af9298e24a7c4a529e4f5eb782f5d7a` |

`boot-274-venus.img` 以 OS2.0.7.0 原厂 `boot.img` 为底：
- kernel 51,161,600 → 50,651,648（**变小**，分区余量更充足）
- ramdisk 21,446,361 **逐字节相同**
- `os_version` `0x1a000194`、`header_version` 3 不变

---

## 5. 风险

1. **未上机验证**。全部是静态核对。
2. **28 个文件停在 285**。树不是纯 274，是“274 主体 + 28 个 Xiaomi 改动文件保持 285”。
   这 28 个文件里含 binder、f2fs、dwc3、erofs、cpucaps —— 都是核心路径，但保持 285 反而自洽。
3. **原厂 43 个模块仍加载不了**。`module_layout` CRC `0xb216eb53`，原厂 `0x1e5b7ab7`。
   与 los 路线同样问题，靠全内置绕开。
4. **LTO/CFI 关闭**，比原厂少一层加固。
5. **`LOCALVERSION` 是 `-VK-Y`**，vermagic 与原厂 `-qgki` 不同（有 `__versions` 时前缀被忽略）。
6. **AVB 未重新签名**，需 BL 解锁 + 校验关闭。

---

## 6. 建议验证顺序

1. 备份 boot：`dd if=/dev/block/by-name/boot$(getprop ro.boot.slot_suffix) of=/sdcard/boot-backup.img`
2. `fastboot boot boot-274-venus.img`（不落盘，失败重启即恢复）
3. 关注：能否进系统、触摸、显示、指纹、Wi-Fi、充电、震动、相机
4. 出问题 `fastboot flash boot boot-backup.img` 回滚

---

## 7. 结论

- **“找 ikun 上游 274”不存在**：ikun 上游是 285。
- **但 285 可以退到 274**：反向应用 11 个 stable 补丁，98.1% 干净，28 个文件保留 285。
- **构建成功**，版本真实 274，MIHW/MILLET/camera_star 全部内置，`millet` 字符串数与原厂一致。
- 这是目前**最接近 ikun 做法**的 274 内核。
