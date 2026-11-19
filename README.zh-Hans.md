<div align="center">

# tmux-bluetooth-revamped

<strong>在 tmux 状态栏显示每个已连接的蓝牙设备及其电量，不阻塞渲染。</strong>

[English](README.md) &nbsp;|&nbsp; [日本語](README.ja.md) &nbsp;|&nbsp; 简体中文 &nbsp;|&nbsp; [繁體中文（香港）](README.zh-HK.md)

[![ci](https://img.shields.io/github/actions/workflow/status/tmux-revamped/tmux-bluetooth-revamped/ci.yml?branch=main&style=flat-square&label=ci)](https://github.com/tmux-revamped/tmux-bluetooth-revamped/actions/workflows/ci.yml)
[![release](https://img.shields.io/github/v/release/tmux-revamped/tmux-bluetooth-revamped?style=flat-square&label=release)](https://github.com/tmux-revamped/tmux-bluetooth-revamped/releases/latest)
[![openssf scorecard](https://img.shields.io/ossf-scorecard/github.com/tmux-revamped/tmux-bluetooth-revamped?style=flat-square&label=openssf%20scorecard)](https://scorecard.dev/viewer/?uri=github.com/tmux-revamped/tmux-bluetooth-revamped)
[![license](https://img.shields.io/github/license/tmux-revamped/tmux-bluetooth-revamped?style=flat-square&label=license)](LICENSE)

<p align="center">
  <a href="#快速开始"><strong>快速开始</strong></a> &nbsp;|&nbsp;
  <a href="#用法">用法</a> &nbsp;|&nbsp;
  <a href="#工作原理">工作原理</a> &nbsp;|&nbsp;
  <a href="#界面">界面</a>
</p>

</div>

<p align="center">
  <img src="screens/hero.gif" alt="tmux 状态栏显示三个蓝牙设备，然后是 bluetooth-revamped list 和它的菜单" width="800">
</p>

```console
$ bluetooth-revamped list
AirPods Pro 85%
MX Master 3S 50%
```

状态栏读取保存在 tmux 选项中的读数，设备查询在后台进行，所以蓝牙响应再慢也不会卡住 tmux。不向磁盘写任何东西。

---

## 快速开始

### 前提条件

| 工具 | 版本 | 用途 |
|:-----|:--------|:---------|
| tmux | 3.2 或更高 | 家族所有成员都支持的最低版本 |
| `system_profiler` | 系统自带 | macOS 上的设备列表，Intel 和 Apple Silicon |
| `upower` | 任意 | Linux 上的设备列表，x86_64 和 arm64 |
| `blueutil` | 任意 | macOS 上的连接、断开和电源，来自 `brew install blueutil` |
| `bluetoothctl` | 任意 | Linux 上的连接、断开、电源和已配对设备，来自 `bluez` 软件包 |
| gum | 可选 | `bluetooth-revamped` 的菜单、表格和颜色；没有它时每个命令都输出纯文本 |

### 安装

在 `~/.tmux.conf` 中加入插件和一个占位符，然后按 `prefix + I`：

```tmux
set -g @plugin 'tmux-revamped/tmux-bluetooth-revamped'
set -g status-right '#{bluetooth_icon} #{bluetooth}'
```

不用 TPM 时，克隆仓库，并在设置 `status-left` 和 `status-right` 的行之后加载入口文件：

```bash
git clone https://github.com/tmux-revamped/tmux-bluetooth-revamped ~/.tmux/plugins/tmux-bluetooth-revamped
```

```tmux
run-shell ~/.tmux/plugins/tmux-bluetooth-revamped/bluetooth-revamped.tmux
```

在克隆的目录中运行 `make install`，还会把 `bluetooth-revamped` 放进 `~/.local/bin`，把它的 man 手册以及 bash、zsh、fish 补全放在 `~/.local/share` 下。

### 验证

```bash
~/.tmux/plugins/tmux-bluetooth-revamped/bin/bluetooth-revamped doctor
```

`doctor` 为每个工具打印一行，并给出找到的设备读取来源。只有缺少必需的工具时，它才以 1 退出。

## 用法

| 占位符 | 输出 |
|:------------|:-------|
| `#{bluetooth}` | 每个已连接的设备及其电量，例如 `AirPods Pro 85%, MX Master 3S 50%` |
| `#{bluetooth_icon}` | 有设备连接时为 `@bluetooth_revamped_icon`，否则为空 |
| `#{bluetooth_count}` | 已连接设备的数量，例如 `2` |
| `#{bluetooth_min}` | 电量最低的设备，例如 `MX Master 3S 50%`；没有设备报告电量时为空 |

| tmux 选项 | 默认值 | 含义 |
|:------------|:--------|:--------|
| `@bluetooth_revamped_interval` | `30` | 读数保持有效的秒数；不是数字的值按 `30` 处理 |
| `@bluetooth_revamped_format` | `%s` | `#{bluetooth}` 的 printf 格式 |
| `@bluetooth_revamped_separator` | `, ` | `#{bluetooth}` 中设备之间的文字 |
| `@bluetooth_revamped_icon` | `BT` | `#{bluetooth_icon}` 的文字 |
| `@bluetooth_revamped_icons` | `0` | `1` 在 `#{bluetooth}` 中每个设备前放上表示其类型的 Nerd Font 字形 |
| `@bluetooth_revamped_notify` | `0` | `1` 在已连接设备的电量低于低电量水平时发送桌面通知 |
| `@bluetooth_revamped_low` | `20` | 低电量水平，单位为百分比 |
| `@bluetooth_revamped_popup_key` | `M-h` | 打开设备弹窗的 prefix 按键，或 `none` |

```tmux
set -g @bluetooth_revamped_separator ' / '
set -g @bluetooth_revamped_format '[%s]'
```

| 命令 | 作用 |
|:--------|:-------------|
| `bluetooth-revamped status NAME` | 打印一个占位符：`device`、`icon`、`count` 或 `min`。占位符调用的就是它 |
| `bluetooth-revamped list` | 立即读取设备，每行一个；`--json` 输出一个对象 |
| `bluetooth-revamped refresh` | 立即为状态栏读取设备 |
| `bluetooth-revamped connect DEVICE` | 按名称或地址连接一个已配对的设备 |
| `bluetooth-revamped disconnect DEVICE` | 断开一个设备 |
| `bluetooth-revamped power on\|off\|toggle` | 打开或关闭蓝牙，或者切换 |
| `bluetooth-revamped popup` | 设备表格，然后连接、断开或切换电源；`prefix M-h` 打开它 |
| `bluetooth-revamped doctor` | 每个依赖一行，包括设备读取来源 |
| `bluetooth-revamped version` | 版本号，然后是 tmux 的版本 |
| `bluetooth-revamped help` | 帮助页面。`man bluetooth-revamped` 说明同样的命令和设置 |
| `bluetooth-revamped` | 在终端中显示菜单：查看设备、检查这台机器，或者查看帮助 |

每个 tmux 选项也都是命令的选项，例如 `--separator ' / '`，以及一个环境变量，例如 `BLUETOOTH_REVAMPED_SEPARATOR`。命令行优先于环境变量，环境变量优先于 tmux 选项。空的 tmux 选项表示使用默认值。`doctor` 会指出值无法识别的设置。`--theme NAME`、`BLUETOOTH_REVAMPED_THEME`、`BLUETOOTH_REVAMPED_ACCENT`、`KODOUGU_THEME`、`KODOUGU_ACCENT`、`NO_COLOR` 和 tmux 选项 `@revamped_theme` 决定命令的外观，与每个 tmux-revamped 工具相同。

```console
$ bluetooth-revamped list --json
{"devices":[{"name":"AirPods Pro","battery":85},{"name":"MX Master 3S","battery":50}]}
```

`prefix M-h` 打开设备弹窗。`@bluetooth_revamped_popup_key` 可以把它移到别的按键，`none` 则不绑定；在插件加载之前你自己绑定的按键会保留，`doctor` 会说明这一点。

电量低时只通知一次，电量回升到低电量水平以上之后再次下降才会再通知。在 `@bluetooth_revamped_notify` 设为 `1` 之前通知是关闭的，同样的状态始终显示在 `#{bluetooth_min}` 中。

## 工作原理

tmux 加载插件时，[`bluetooth-revamped.tmux`](bluetooth-revamped.tmux) 把 `status-left` 和 `status-right` 中的每个占位符换成调用 `bluetooth-revamped status` 的 `#()`。这个调用立即打印保存在 `@bluetooth_revamped_device` 中的读数。读数比间隔更旧时，它还会在后台开始一次读取；`@bluetooth_revamped_device_lock` 中的锁保证并行的调用不会再开始第二次，下一次重绘就会显示结果。

每次读取还会把所有已配对设备的状态、地址、类型和电量保存在 `@bluetooth_revamped_details` 中；弹窗、操作和图标都读取它。

macOS 读取 `system_profiler SPBluetoothDataType`，并通过 `blueutil` 操作。Linux 用 `bluetoothctl` 列出已配对设备，并通过它操作。AirPods 会报告每只耳机和充电盒的电量，插件显示较低的耳机电量。Linux 读取 `upower --dump`，只统计蓝牙设备，所以笔记本电脑的电池不会出现。

<a id="界面"></a>

## 界面

<details>
<summary>每个界面都用 <code>make screens</code> 在真实的 tmux 中录制，按下的每个键都显示在状态栏上</summary>
<br>

<table>
<tr>
<td width="50%" valign="top"><img src="screens/status.png" alt="bluetooth-revamped：状态栏中的每个占位符"><br><sub>状态栏中的每个占位符，来自 <code>hero.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/list.png" alt="bluetooth-revamped：list"><br><sub><code>list</code>，来自 <code>hero.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/json.png" alt="bluetooth-revamped：list --json"><br><sub><code>list --json</code>，来自 <code>hero.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/menu.png" alt="bluetooth-revamped：菜单"><br><sub>菜单，来自 <code>hero.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/menu-list.png" alt="bluetooth-revamped：从菜单查看设备"><br><sub>从菜单查看设备，来自 <code>hero.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/status-command.png" alt="bluetooth-revamped：status count 和 status min"><br><sub><code>status count</code> 和 <code>status min</code>，来自 <code>stills.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/options.png" alt="bluetooth-revamped：分隔符、格式和图标选项"><br><sub>分隔符、格式和图标选项，来自 <code>stills.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/refresh.png" alt="bluetooth-revamped：refresh"><br><sub><code>refresh</code>，来自 <code>stills.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/doctor.png" alt="bluetooth-revamped：doctor"><br><sub><code>doctor</code>，来自 <code>stills.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/plain-menu.png" alt="bluetooth-revamped：没有 gum 时的菜单"><br><sub>没有 gum 时的菜单，来自 <code>stills.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/plain-doctor.png" alt="bluetooth-revamped：没有 gum 时的 doctor，使用 macOS 自带的工具"><br><sub>没有 gum 时的 doctor，使用 macOS 自带的工具，来自 <code>stills.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/version.png" alt="bluetooth-revamped：版本"><br><sub>版本，来自 <code>stills.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/error.png" alt="bluetooth-revamped：错误的占位符名称"><br><sub>错误的占位符名称，来自 <code>stills.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/accent.png" alt="bluetooth-revamped：来自 BLUETOOTH_REVAMPED_ACCENT 的强调色"><br><sub>来自 <code>BLUETOOTH_REVAMPED_ACCENT</code> 的强调色，来自 <code>stills.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/popup.png" alt="bluetooth-revamped：prefix M-h 上的设备弹窗"><br><sub><code>prefix M-h</code> 上的设备弹窗，来自 <code>actions.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/connect.png" alt="bluetooth-revamped：从弹窗连接的设备"><br><sub>从弹窗连接的设备，来自 <code>actions.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/icons.png" alt="bluetooth-revamped：每种设备类型的字形"><br><sub>每种设备类型的字形，来自 <code>actions.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/power.png" alt="bluetooth-revamped：power toggle 和 disconnect"><br><sub><code>power toggle</code> 和 <code>disconnect</code>，来自 <code>actions.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/themes.png" alt="bluetooth-revamped：六个主题下的标题"><br><sub>六个主题下的标题，来自 <code>themes.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/help.png" alt="bluetooth-revamped：帮助页面"><br><sub>帮助页面，来自 <code>help.tape</code></sub></td>
</tr>
</table>

</details>

## 可移植性

插件是 POSIX `sh`。CI 在下面每一行上运行全部测试。

| Shell | 状态 |
|:------|:-------|
| `dash`、macOS 上的 `/bin/sh` | 支持 |
| `bash` 3.2 和 5.x、系统自带的 `zsh` 和 Homebrew 的 `zsh` | 支持 |

| 系统 | 状态 |
|:-------|:-------|
| macOS | Apple Silicon 和 Intel 上的 Tahoe，使用系统自带的工具、Homebrew 的 GNU 工具和 Homebrew 的 uutils |
| Linux | x86_64 和 arm64 上的 Ubuntu 26.04，使用 GNU coreutils、uutils 和 BusyBox |
| FreeBSD、OpenBSD、NetBSD | 不在 CI 覆盖范围内；占位符为空，`doctor` 说明没有读取来源 |

## 开发

| 命令 | 运行内容 |
|:--------|:-------------|
| `make fmt` | 对每个脚本运行 shfmt `-i 2` |
| `make lint` | shfmt、ShellCheck、mandoc、yamllint 和 actionlint，零告警 |
| `make test` | 在系统 `sh` 下运行 bats 测试 |
| `make test-all` | 在每个已安装的 shell 下运行测试，macOS 上包括 bash 和 zsh 的两种构建 |
| `make test-linux` | 在 Ubuntu 容器中运行测试 |
| `make coverage` | 在这台 Mac 和 Ubuntu 容器中运行 bashcov，合并后以 100% 为门槛 |
| `make screens` | 用 VHS 在 tmux 中从真实插件录制上面的界面，在 macOS 上运行 |
| `make install` | 把命令、man 手册和补全安装到 `PREFIX` 下 |

在 macOS 上，运行 `brew bundle` 会根据 [`Brewfile`](Brewfile) 安装这些目标用到的所有工具。

提交遵循 Conventional Commits 格式，直接进入 `main`。`main` 上的 `ci` 通过后，`release.yml` 运行 semantic-release：自上一个标签以来的每个 `feat` 或 `fix` 都会发布新版本，更新版本常量，并把说明写进 [`CHANGELOG.md`](CHANGELOG.md)。

## 许可证

[MIT](LICENSE)，copyright Gustavo Franco。

<!-- family:begin -->

## tmux-revamped 插件家族

这个插件是 tmux-revamped 插件家族的一员。每个成员都带有 [`FAMILY.md`](FAMILY.md) 中相同的约定和相同的共享库，并且设计为一起安装：没有成员占用另一个成员占用的按键或 tmux 选项。

在一个成员中发现的缺陷，要在全部成员中排查之后才算修复完成。

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
| [`tmux-plugin-template`](https://github.com/tmux-revamped/tmux-plugin-template) | tmux-revamped 插件的起点：共享库、bats 测试框架和 CI |
| [`tmux-pomodoro-revamped`](https://github.com/tmux-revamped/tmux-pomodoro-revamped) | tmux 状态栏中的番茄钟计时器，所有状态都保存在 tmux 选项中，不使用临时文件 |
| [`tmux-ram-revamped`](https://github.com/tmux-revamped/tmux-ram-revamped) | 在 tmux 状态栏显示内存、交换空间和内存压力，在后台采样，渲染从不等待 |
| [`tmux-reorder-revamped`](https://github.com/tmux-revamped/tmux-reorder-revamped) | 用鼠标在 tmux 状态栏上拖动窗口标签来移动该窗口 |
| [`tmux-scroll-revamped`](https://github.com/tmux-revamped/tmux-scroll-revamped) | 将鼠标滚轮交给能自行滚动的应用，其他情况下进入 tmux 复制模式 |
| [`tmux-sensible-revamped`](https://github.com/tmux-revamped/tmux-sensible-revamped) | 按 tmux 版本和终端区分的合理默认设置，不改动你自己设置的选项 |
| [`tmux-tiling-revamped`](https://github.com/tmux-revamped/tmux-tiling-revamped) | tmux 的平铺窗口管理：八种布局，包括 BSP dwindle 和 spiral，并支持撤销布局 |
| [`tmux-time-revamped`](https://github.com/tmux-revamped/tmux-time-revamped) | 状态栏中的本地时钟和世界时钟，按一天中的时段着色，并提供倒计时和夏令时提醒 |
| [`tmux-weather-revamped`](https://github.com/tmux-revamped/tmux-weather-revamped) | 在后台从 wttr.in 获取天气并显示在状态栏，状态栏无需等待 |

<!-- family:end -->
