# Star 5.4.274 v8（ReSukiSU + SuSFS v2.3.0）

## 1. v7 反复重启的根因（已修复）

**BakaSU 在 `CONFIG_KSU_SUSFS=y` 下编译了 6.1+ 的 `faccessat` / `stat` 钩子实现，而本树是 5.4。**

`KernelSU/kernel/feature/sucompat.c` 用 `#ifdef CONFIG_KSU_SUSFS` 选择函数体：

| 分支 | 第二参数 | 实现 |
|---|---|---|
| `CONFIG_KSU_SUSFS=y` | `struct filename **` | 直接读 `(*filename)->name` |
| 否则 | `const char __user **` | `ksu_strncpy_from_user_nofault()` 拷到栈上再比较 |

5.4 的调用点传的是后者：

- `fs/open.c:364` — `do_faccessat(dfd, const char __user *filename, mode)` → `ksu_handle_faccessat(&dfd, &filename, &mode, NULL)`
- `fs/stat.c:234` — `vfs_statx(dfd, const char __user *filename, ...)` → `ksu_handle_stat(&dfd, &filename, &flags)`

于是 `*filename` 实际是**用户态地址**，被当成 `struct filename *` 去解引用 `(*filename)->name`（偏移 8）→ 内核态访问用户地址 → data abort。

`ksu_su_compat_enabled` 是 `DEFINE_STATIC_KEY_TRUE`（默认开），所以这个解引用在**每一次** `access()` / `stat()` 上都会发生。Android 一阶段 init 开机期间高频调用这两个系统调用，因此：

- 内核 oops 打死 init → `Attempted to kill init` → 重启 → 无限 bootloop
- `PANIC_ON_OOPS` 在 v7 里没开，所以不是立刻 panic 而是 oops 后重启，表现就是“反复重启”

修复：加版本闸门 `KSU_HANDLE_FACCESSAT_STAT_TAKES_FILENAME`，只在 `LINUX_VERSION_CODE >= 6.1` 时选 `struct filename` 分支（见 `ksu-patches/kernelsu-5.4-faccessat-stat-hook-signature.patch`）。

**编译产物验证**：`ksu_handle_faccessat` 现在把 `*filename_user` 传进 `strncpy_from_unsafe_user`（长度 16），再 `memcmp(..., su_path, 15)` —— 即 5.4 正确路径；v7 的同一符号走的是 `kern_path` + `memcpy((*filename)->name, ...)`。

其余钩子（`execveat` / `sys_read` / `sys_reboot` / `setresuid` / `input_handle_event`）签名与 5.4 调用点一致，无同类问题。

## 2. 与开机慢相关的配置改动（假设，非结论）

v8 同时把几项“偏离 stock”的配置拉回原厂状态，作为开机慢的第二组假设：

| 项 | v7 | v8 | stock | 理由 |
|---|---|---|---|---|
| `CONFIG_PANIC_TIMEOUT` | -1 | **5** | -1 | 出问题自动回 recovery，不黑屏死等 |
| `CONFIG_CMDLINE` | `cgroup_disable=pressure` | 追加 `ramoops_memreserve=4M` | `ramoops_memreserve=4M` | pstore/console-ramoops 才能落地，root 后可取证 |
| `CONFIG_LRU_GEN` | y | **n** | n | 5.4 上的 MGLRU 是回移，stock 不用；开机期内存回收路径可疑 |
| `CONFIG_PAGE_OWNER` | y | **n** | n | 调试功能，无收益 |
| `CONFIG_SUSPEND_SKIP_SYNC` | y | **n** | n | 非原厂行为，与休眠路径相关 |
| `CONFIG_INPUT_QCOM_HV_HAPTICS` | y | **n** | n | stock 不编译此驱动，与 aw8697 震动修复无关 |

**开机慢本身还没有证据链**：v7 无 root，`dmesg` / `/sys/fs/pstore` 都被 SELinux 拒，`logcat -b kernel` 对 shell 为空。v8 刷入后有 KSU root，可直接 `su -c dmesg` 取开机时间线，或用 pstore 的 console-ramoops 取上一次启动的完整内核日志。若 v8 仍慢，就能用日志区分是「源码 274 降级（venus 285→274 reverse-apply 留下 ~20 个混合态文件）」还是「配置」。

## 3. 构建

```bash
./build-v8.sh            # 见脚本内注释：先在 KernelSU 子模块应用补丁，再编 Image+dtbs
```

版本串：`5.4.274-qgki-su-g4dfe63e0666f`（`CONFIG_LOCALVERSION="-qgki-su-g4dfe63e0666f"`，`LOCALVERSION=""`）。

## 4. 刷入

```bash
fastboot boot boot-5.4.274-star-v8-ksu.img     # 先试启动，不写分区
# 正常启动后再固化：
fastboot flash boot boot-5.4.274-star-v8-ksu.img
# 或 TWRP 卡刷 Star-5.4.274-star-v8-ksu-AnyKernel3.zip
```

## 5. 注意

- 本树的 `kernel/Makefile` 把 IKCONFIG 写死成 `arch/arm64/configs/haydn-stock_defconfig`，所以 Image 里内嵌的 `/proc/config.gz` **不是**本次编译用的 .config。校验配置请看 `star-5.4.274-ksu.config` 或构建目录的 `.config`。
- `drivers/kernelsu` 是指向 `../KernelSU/kernel` 的符号链接，已入库（mode 120000）。
