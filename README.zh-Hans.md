<div align="center">

# tmux-bluetooth-revamped

<strong>在 tmux 状态栏显示每个已连接的蓝牙设备及其电量，不阻塞渲染。</strong>

[English](README.md) | [日本語](README.ja.md) | 简体中文 | [繁體中文（香港）](README.zh-HK.md)

[![Tests](https://github.com/tmux-revamped/tmux-bluetooth-revamped/actions/workflows/tests.yml/badge.svg)](https://github.com/tmux-revamped/tmux-bluetooth-revamped/actions/workflows/tests.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-1.2.0-blue.svg)](CHANGELOG.md)

<p align="center">
  <a href="#what-it-does">功能</a> |
  <a href="#requirements">环境要求</a> |
  <a href="#installation">安装</a> |
  <a href="#usage">用法</a> |
  <a href="#configuration">配置</a> |
  <a href="#key-bindings">快捷键</a> |
  <a href="#how-it-works">工作原理</a>
</p>

</div>

**4** 个占位符。**4** 个选项。默认每 **30** 秒查询一次设备。CI 在 **10** 种 Linux 和 macOS 工具链组合上运行测试。

---

<a id="what-it-does"></a>

## 功能

插件把 `status-left` 和 `status-right` 中的 `#{bluetooth*}` 占位符替换为已连接的蓝牙设备及其电量，例如 `AirPods 85%, MX Master 50%`。状态栏读取缓存在 tmux 选项中的值，设备查询在后台进行。不向磁盘写入任何内容。

- 不报告电量的设备只显示名称。
- 报告左耳、右耳和充电盒电量的 AirPods 只列出一次，显示两只耳机中较低的电量。
- 在 Linux 上只列出蓝牙设备，因此不会出现笔记本电池。
- 没有设备连接时，设备列表和图标显示为空，数量显示为 `0`。

<a id="requirements"></a>

## 环境要求

| 工具 | 版本 | 用途 |
|:-----|:--------|:-----------|
| tmux | 3.2 或更高 | 插件家族的最低版本 |
| bash | 3.2 或更高 | 所有脚本，包括 macOS 的 `/bin/bash` |
| `upower` | 任意 | 仅 Linux，设备列表 |

| 平台 | 数据源 |
|:---------|:-------|
| macOS，Intel 和 Apple Silicon | 系统自带的 `system_profiler SPBluetoothDataType` |
| Linux，x86_64 和 arm64 | `upower --dump` |

<a id="installation"></a>

## 安装

### 使用 TPM

把插件和占位符加入 `~/.tmux.conf`，然后按 `prefix + I`：

```tmux
set -g @plugin 'tmux-revamped/tmux-bluetooth-revamped'
set -g status-right '#{bluetooth_icon} #{bluetooth}'
```

### 手动安装

```bash
git clone https://github.com/tmux-revamped/tmux-bluetooth-revamped ~/.tmux/plugins/tmux-bluetooth-revamped
```

然后把这一行加到 `~/.tmux.conf` 中设置 `status-left` 和 `status-right` 的行之后，并重新加载 tmux：

```tmux
run-shell ~/.tmux/plugins/tmux-bluetooth-revamped/bluetooth-revamped.tmux
```

<a id="usage"></a>

## 用法

在 `status-left` 或 `status-right` 中写入占位符，插件加载时会替换它们。完整示例见 [`examples/status-right.tmux.conf`](examples/status-right.tmux.conf)。

| 占位符 | 输出 |
|:------------|:-------|
| `#{bluetooth}` | 每个已连接的设备及其电量，例如 `AirPods 85%, MX Master 50%` |
| `#{bluetooth_icon}` | 有设备连接时为 `@bluetooth_revamped_icon`，否则为空 |
| `#{bluetooth_count}` | 已连接设备的数量，例如 `2` |
| `#{bluetooth_min}` | 电量最低的设备，例如 `MX Master 50%`；没有设备报告电量时为空 |

<a id="configuration"></a>

## 配置

| 选项 | 默认值 | 含义 |
|:-------|:--------|:--------|
| `@bluetooth_revamped_interval` | `30` | 设备读数保持有效的秒数；不是数字的值会回退为 `30` |
| `@bluetooth_revamped_format` | `%s` | `#{bluetooth}` 的 printf 格式 |
| `@bluetooth_revamped_separator` | `, ` | `#{bluetooth}` 中设备之间的文字 |
| `@bluetooth_revamped_icon` | `BT` | `#{bluetooth_icon}` 的文字 |

```tmux
set -g @bluetooth_revamped_separator ' | '
set -g @bluetooth_revamped_format '[%s]'
```

### 内部状态

以下选项由插件自己写入，请不要设置。

| 选项 | 内容 |
|:-------|:------|
| `@bluetooth_revamped_device` | 缓存的设备列表，每行一个设备 |
| `@bluetooth_revamped_device_ts`、`@bluetooth_revamped_device_lock` | 读取列表的时间，以及是否正在刷新 |

<a id="key-bindings"></a>

## 快捷键

插件不绑定任何按键。

<a id="how-it-works"></a>

## 工作原理

每个占位符都会变成调用 [`src/bluetooth.sh`](src/bluetooth.sh) 的 `#()`。调用会立即输出缓存的设备列表。当列表比 `@bluetooth_revamped_interval` 秒旧时，它还会启动一次后台刷新；刷新受锁保护，并行的调用不会再启动第二次。下一次重绘状态栏时显示新的列表。

<a id="development"></a>

## 开发

| 命令 | 运行内容 |
|:--------|:-------------|
| `make test` | [`test/`](test) 下的 bats 测试 |
| `make lint` | 对所有 shell 文件运行 shellcheck |
| `make coverage` | 在 Linux 上用 kcov 统计行覆盖率，低于 95% 时失败 |

<a id="license"></a>

## 许可证

[MIT](LICENSE)，copyright Gustavo Franco。

<!-- family:begin -->

## tmux-revamped 插件家族

本插件是 tmux-revamped 插件家族的一员。每个成员都带有 [`FAMILY.md`](FAMILY.md) 中的同一份约定、`family/` 下的同一套工具和同一个共享库，并由校验和清单保证逐字节一致。这些成员可以一起安装：任何成员都不会占用其他成员使用的按键或 tmux 选项。

在一个成员中发现的缺陷，要在全部成员中排查之后才算修复完成。这项义务写在约定里，而不是靠记忆，`family/bin/sweep` 负责执行它。

| 成员 | 功能 |
|---|---|
| [`tmux-autoreload-revamped`](https://github.com/tmux-revamped/tmux-autoreload-revamped) | 编辑并保存 tmux 配置后，它会自动重新加载，无需按键，也无需命令 |
| [`tmux-battery-revamped`](https://github.com/tmux-revamped/tmux-battery-revamped) | 在 tmux 状态栏显示电池状态，从不阻塞状态栏渲染 |
| [`tmux-bluetooth-revamped`](https://github.com/tmux-revamped/tmux-bluetooth-revamped) | **本插件**，在 tmux 状态栏显示每个已连接的蓝牙设备及其电量，不阻塞渲染 |
| [`tmux-cpu-revamped`](https://github.com/tmux-revamped/tmux-cpu-revamped) | 在 tmux 状态栏显示 CPU 负载、温度和频率，从不阻塞渲染 |
| [`tmux-disk-revamped`](https://github.com/tmux-revamped/tmux-disk-revamped) | 在 tmux 状态栏显示磁盘用量，从不阻塞状态栏渲染 |
| [`tmux-extract-revamped`](https://github.com/tmux-revamped/tmux-extract-revamped) | 用 fzf 从屏幕上挑选 URL、路径、哈希或任意其他词元，并输入到光标处，全部用纯 shell 实现 |
| [`tmux-fzf-revamped`](https://github.com/tmux-revamped/tmux-fzf-revamped) | 在弹出窗口中的 fzf 选择器里切换、关闭、重命名或创建 tmux 会话、窗口和窗格 |
| [`tmux-git-revamped`](https://github.com/tmux-revamped/tmux-git-revamped) | 在 tmux 状态栏中显示活动窗格的 git 分支、改动和托管平台计数，且不阻塞渲染 |
| [`tmux-gpu-revamped`](https://github.com/tmux-revamped/tmux-gpu-revamped) | 在 tmux 状态栏中显示 NVIDIA、AMD、Intel 和 Apple GPU 的负载、温度、频率、功耗和显存 |
| [`tmux-kube-revamped`](https://github.com/tmux-revamped/tmux-kube-revamped) | 在 tmux 状态栏中显示当前的 Kubernetes 上下文和命名空间，不依赖 kubectl，直接解析 kubeconfig |
| [`tmux-launcher-revamped`](https://github.com/tmux-revamped/tmux-launcher-revamped) | 在弹出窗口或新窗口中启动任意 TUI 应用，从当前窗格的目录开始，每个应用可配置一个按键 |
| [`tmux-logging-revamped`](https://github.com/tmux-revamped/tmux-logging-revamped) | 将任意窗格保存到文件：实时日志、完整回滚缓冲区或一次性截图 |
| [`tmux-music-revamped`](https://github.com/tmux-revamped/tmux-music-revamped) | 在 tmux 状态栏显示正在播放的曲目，从不阻塞状态栏渲染 |
| [`tmux-network-revamped`](https://github.com/tmux-revamped/tmux-network-revamped) | 在 tmux 状态栏显示网络吞吐量，从不阻塞渲染 |
| [`tmux-pain-control-revamped`](https://github.com/tmux-revamped/tmux-pain-control-revamped) | tmux 的窗格和窗口管理按键，适配 tmux 版本，兼容 vim，每个 prefix 按键都可禁用 |
| [`tmux-persist-revamped`](https://github.com/tmux-revamped/tmux-persist-revamped) | 保存 tmux 的所有会话、窗口和窗格，按定时器自动保存，并在重启后全部恢复 |
| [`tmux-plugin-template`](https://github.com/tmux-revamped/tmux-plugin-template) | tmux-revamped 插件的起点：共享库、bats 测试框架、CI 和系列工具 |
| [`tmux-pomodoro-revamped`](https://github.com/tmux-revamped/tmux-pomodoro-revamped) | tmux 状态栏中的番茄钟计时器，所有状态都保存在 tmux 选项中，不使用临时文件 |
| [`tmux-ram-revamped`](https://github.com/tmux-revamped/tmux-ram-revamped) | 在 tmux 状态栏显示内存、交换空间和内存压力，在后台采样，渲染从不等待 |
| [`tmux-reorder-revamped`](https://github.com/tmux-revamped/tmux-reorder-revamped) | 用鼠标在 tmux 状态栏上拖动窗口标签来移动该窗口 |
| [`tmux-scroll-revamped`](https://github.com/tmux-revamped/tmux-scroll-revamped) | 将鼠标滚轮交给能自行滚动的应用，其他情况下进入 tmux 复制模式 |
| [`tmux-sensible-revamped`](https://github.com/tmux-revamped/tmux-sensible-revamped) | 按 tmux 版本和终端区分的合理默认设置，不改动你自己设置的选项 |
| [`tmux-tiling-revamped`](https://github.com/tmux-revamped/tmux-tiling-revamped) | tmux 的平铺窗口管理：八种布局，包括 BSP dwindle 和 spiral，并支持撤销布局 |
| [`tmux-time-revamped`](https://github.com/tmux-revamped/tmux-time-revamped) | 状态栏中的本地时钟和世界时钟，按一天中的时段着色，并提供倒计时和夏令时提醒 |
| [`tmux-weather-revamped`](https://github.com/tmux-revamped/tmux-weather-revamped) | 在后台从 wttr.in 获取天气并显示在状态栏，状态栏无需等待 |

### 检查安装

所有成员都在磁盘上时，一条命令即可报告它们之间的任何冲突：

```sh
family/bin/doctor --live
```

它读取每个成员和正在运行的 tmux 服务器，报告重复的按键、重复的状态占位符、不符合命名规则的选项，以及约定版本落后的成员。

<!-- family:end -->
