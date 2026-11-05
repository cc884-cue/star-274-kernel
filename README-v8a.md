# v8a — 5.4.274 内核（ReSukiSU / BakaSU，manual hook，无 SuSFS）

**定位：v8 的隔离对照版 + 保底可刷版。**

v8 带 SuSFS inline hook；v8a 把 SuSFS 整体关掉，改走 BakaSU 的 `CONFIG_KSU_MANUAL_HOOK`
路径（含 `AUTO_SETUID/INITRC/INPUT` 三个自动钩子 + 手工补的
`ksu_handle_newfstat_ret` / `ksu_handle_fstat64_ret`）。除了 root 隐藏相关的 SuSFS 功能，
其余与 v8 完全同源、同配置。

## 判读方式

- **v8a 能开机、v8 不能** → 问题在 SuSFS inline hook，与 274 源码降级无关。
- **两个都不能开机** → 问题在 274 源码侧 / 与 root 无关的通用缺陷。
- **两个都能开机** → v7 的白屏/重启就是 v8 修掉的那个 5.4 钩子签名 bug；用 v8 拿 SuSFS 功能。

## 已验证（离线）

| 证据 | 结果 |
|---|---|
| `ksu_handle_newfstat_ret` / `ksu_handle_fstat64_ret` 被调用 | `__arm64_sys_newfstat` 分别 `bl` 到两个符号 ✓ |
| `ksu_handle_faccessat` 走 5.4 分支 | `strncpy_from_unsafe_user` → `memcmp` → `override_creds` → `getname_kernel` → `__arch_copy_to_user` ✓ |
| 5.4 签名窗口 `610240f9e063009102028052` | Image 2 处、boot.img 2 处（v7 为 0 处）✓ |
| SuSFS 残留 | `System.map` 中 susfs 符号 0 个 ✓ |
| ramdisk | 与 stock **逐字节相同**（sha `cf3557840e6837fc…`）✓ |

## 资产

- `boot-5.4.274-star-v8a-ksu.img` — 201326592 字节，可直接 `fastboot boot`
- `Image-5.4.274-star-v8a-ksu` — 46907904 字节，供 AK3 / 自行打包
- `Star-5.4.274-star-v8a-ksu-AnyKernel3.zip` — 从 recovery / 面具刷入
- `SHA256SUMS-v8a-ksu.txt`

## 刷机顺序（不写分区）

```sh
fastboot boot boot-5.4.274-star-v8a-ksu.img
```

开机后再考虑 `fastboot flash boot` 或刷 AK3 zip。刷前留好 stock `boot.img`。

## 内核版本串

`Linux version 5.4.274-qgki-su-g4dfe63e0666f`

## 已知限制

- 没有 SuSFS：SUS_PATH / open redirect / kstat 伪装 / uname 伪装等隐藏能力全部缺席，
  对检测严格的应用不保证能过。
- `CONFIG_KSU_MANUAL_HOOK` 的钩子点比 inline hook 少（例如部分 statx/execveat 子路径），
  日常 `su` / 授权 / 模块够用，但不等于 v8 的覆盖面。
