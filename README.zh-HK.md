<div align="center">

# tmux-bluetooth-revamped

<strong>在 tmux 狀態列顯示每部已連接的藍牙裝置及其電量，不阻塞繪製。</strong>

[English](README.md) &nbsp;|&nbsp; [日本語](README.ja.md) &nbsp;|&nbsp; [简体中文](README.zh-Hans.md) &nbsp;|&nbsp; 繁體中文（香港）

[![ci](https://img.shields.io/github/actions/workflow/status/tmux-revamped/tmux-bluetooth-revamped/ci.yml?branch=main&style=flat-square&label=ci)](https://github.com/tmux-revamped/tmux-bluetooth-revamped/actions/workflows/ci.yml)
[![release](https://img.shields.io/github/v/release/tmux-revamped/tmux-bluetooth-revamped?style=flat-square&label=release)](https://github.com/tmux-revamped/tmux-bluetooth-revamped/releases/latest)
[![openssf scorecard](https://img.shields.io/ossf-scorecard/github.com/tmux-revamped/tmux-bluetooth-revamped?style=flat-square&label=openssf%20scorecard)](https://scorecard.dev/viewer/?uri=github.com/tmux-revamped/tmux-bluetooth-revamped)
[![license](https://img.shields.io/github/license/tmux-revamped/tmux-bluetooth-revamped?style=flat-square&label=license)](LICENSE)

<p align="center">
  <a href="#快速開始"><strong>快速開始</strong></a> &nbsp;|&nbsp;
  <a href="#用法">用法</a> &nbsp;|&nbsp;
  <a href="#運作原理">運作原理</a> &nbsp;|&nbsp;
  <a href="#畫面">畫面</a>
</p>

</div>

<p align="center">
  <img src="screens/hero.gif" alt="tmux 狀態列顯示三部藍牙裝置，然後是 bluetooth-revamped list 和它的選單" width="800">
</p>

```console
$ bluetooth-revamped list
AirPods Pro 85%
MX Master 3S 50%
```

狀態列讀取存放在 tmux 選項中的讀數，裝置查詢在背景進行，因此藍牙回應再慢亦不會令 tmux 停頓。不會寫入磁碟。

---

## 快速開始

### 前提條件

| 工具 | 版本 | 用途 |
|:-----|:--------|:---------|
| tmux | 3.2 或以上 | 所有成員都支援的系列下限 |
| `system_profiler` | 系統內建 | macOS 上的裝置清單，Intel 和 Apple Silicon |
| `upower` | 任何 | Linux 上的裝置清單，x86_64 和 arm64 |
| `blueutil` | 任何 | macOS 上的連接、中斷和電源，來自 `brew install blueutil` |
| `bluetoothctl` | 任何 | Linux 上的連接、中斷、電源和已配對裝置，來自 `bluez` 套件 |
| gum | 可選 | `bluetooth-revamped` 的選單、表格和顏色；沒有它時每個指令都輸出純文字 |

### 安裝

在 `~/.tmux.conf` 中加入插件和一個佔位符，然後按 `prefix + I`：

```tmux
set -g @plugin 'tmux-revamped/tmux-bluetooth-revamped'
set -g status-right '#{bluetooth_icon} #{bluetooth}'
```

不使用 TPM 時，複製儲存庫，並在設定 `status-left` 和 `status-right` 的行之後載入入口腳本：

```bash
git clone https://github.com/tmux-revamped/tmux-bluetooth-revamped ~/.tmux/plugins/tmux-bluetooth-revamped
```

```tmux
run-shell ~/.tmux/plugins/tmux-bluetooth-revamped/bluetooth-revamped.tmux
```

在複製的目錄中執行 `make install`，亦會把 `bluetooth-revamped` 放入 `~/.local/bin`，並把它的 man 手冊以及 bash、zsh、fish 自動完成放在 `~/.local/share` 下。

### 驗證

```bash
~/.tmux/plugins/tmux-bluetooth-revamped/bin/bluetooth-revamped doctor
```

`doctor` 為每個工具列出一行，並顯示找到的裝置讀取來源。只有缺少必需的工具時，它才會以 1 結束。

## 用法

| 佔位符 | 輸出 |
|:------------|:-------|
| `#{bluetooth}` | 每部已連接的裝置及其電量，例如 `AirPods Pro 85%, MX Master 3S 50%` |
| `#{bluetooth_icon}` | 有裝置連接時為 `@bluetooth_revamped_icon`，否則為空 |
| `#{bluetooth_count}` | 已連接裝置的數目，例如 `2` |
| `#{bluetooth_min}` | 電量最低的裝置，例如 `MX Master 3S 50%`；沒有裝置報告電量時為空 |

| tmux 選項 | 預設值 | 意思 |
|:------------|:--------|:--------|
| `@bluetooth_revamped_interval` | `30` | 讀數保持有效的秒數；不是數字的值當作 `30` |
| `@bluetooth_revamped_format` | `%s` | `#{bluetooth}` 的 printf 格式 |
| `@bluetooth_revamped_separator` | `, ` | `#{bluetooth}` 中裝置之間的文字 |
| `@bluetooth_revamped_icon` | `BT` | `#{bluetooth_icon}` 的文字 |
| `@bluetooth_revamped_icons` | `0` | `1` 在 `#{bluetooth}` 中每部裝置前加上表示其類型的 Nerd Font 字形 |
| `@bluetooth_revamped_notify` | `0` | `1` 在已連接裝置的電量低於低電量水平時發出桌面通知 |
| `@bluetooth_revamped_low` | `20` | 低電量水平，以百分比計 |
| `@bluetooth_revamped_popup_key` | `M-h` | 開啟裝置彈出視窗的 prefix 按鍵，或 `none` |

```tmux
set -g @bluetooth_revamped_separator ' / '
set -g @bluetooth_revamped_format '[%s]'
```

| 指令 | 作用 |
|:--------|:-------------|
| `bluetooth-revamped status NAME` | 列出一個佔位符：`device`、`icon`、`count` 或 `min`。佔位符呼叫的就是它 |
| `bluetooth-revamped list` | 立即讀取裝置，每行一部；`--json` 輸出一個物件 |
| `bluetooth-revamped refresh` | 立即為狀態列讀取裝置 |
| `bluetooth-revamped connect DEVICE` | 按名稱或地址連接一部已配對的裝置 |
| `bluetooth-revamped disconnect DEVICE` | 中斷一部裝置 |
| `bluetooth-revamped power on\|off\|toggle` | 開啟或關閉藍牙，或者切換 |
| `bluetooth-revamped popup` | 裝置表格，然後連接、中斷或切換電源；`prefix M-h` 會開啟它 |
| `bluetooth-revamped doctor` | 每個依賴項目一行，包括裝置讀取來源 |
| `bluetooth-revamped version` | 版本，然後是 tmux 的版本 |
| `bluetooth-revamped help` | 說明頁面。`man bluetooth-revamped` 說明同樣的指令和設定 |
| `bluetooth-revamped` | 在終端機中顯示選單：查看裝置、檢查這部電腦，或查看說明 |

每個 tmux 選項亦是指令的選項，例如 `--separator ' / '`，以及一個環境變數，例如 `BLUETOOTH_REVAMPED_SEPARATOR`。指令列優先於環境變數，環境變數優先於 tmux 選項。`--theme NAME`、`BLUETOOTH_REVAMPED_THEME`、`BLUETOOTH_REVAMPED_ACCENT`、`KODOUGU_THEME`、`KODOUGU_ACCENT`、`NO_COLOR` 和 tmux 選項 `@revamped_theme` 決定指令的外觀，與每個 tmux-revamped 工具相同。

```console
$ bluetooth-revamped list --json
{"devices":[{"name":"AirPods Pro","battery":85},{"name":"MX Master 3S","battery":50}]}
```

`prefix M-h` 會開啟裝置彈出視窗。`@bluetooth_revamped_popup_key` 可把它移到其他按鍵，`none` 則不綁定；在插件載入之前你自己綁定的按鍵會保留，`doctor` 亦會說明。

電量偏低時只會通知一次，電量回升至低電量水平以上後再次下降才會再通知。在 `@bluetooth_revamped_notify` 設為 `1` 之前通知是關閉的，同樣的狀態一直顯示在 `#{bluetooth_min}` 中。

## 運作原理

tmux 載入插件時，[`bluetooth-revamped.tmux`](bluetooth-revamped.tmux) 把 `status-left` 和 `status-right` 中的每個佔位符換成呼叫 `bluetooth-revamped status` 的 `#()`。這個呼叫會立即列出存放在 `@bluetooth_revamped_device` 中的讀數。讀數比間隔更舊時，它亦會在背景開始一次讀取；`@bluetooth_revamped_device_lock` 中的鎖定確保並行的呼叫不會開始第二次，下一次重繪便會顯示結果。

每次讀取亦會把所有已配對裝置的狀態、地址、類型和電量存放在 `@bluetooth_revamped_details`；彈出視窗、操作和圖示都會讀取它。

macOS 讀取 `system_profiler SPBluetoothDataType`，並透過 `blueutil` 操作。Linux 以 `bluetoothctl` 列出已配對裝置，並透過它操作。AirPods 會報告每隻耳機和充電盒的電量，插件顯示較低的耳機電量。Linux 讀取 `upower --dump`，只計算藍牙裝置，因此手提電腦的電池不會出現。

<a id="畫面"></a>

## 畫面

<details>
<summary>每個畫面都以 <code>make screens</code> 在真實的 tmux 中錄製，按下的每個按鍵都顯示在狀態列上</summary>
<br>

<table>
<tr>
<td width="50%" valign="top"><img src="screens/status.png" alt="bluetooth-revamped：狀態列中的每個佔位符"><br><sub>狀態列中的每個佔位符，來自 <code>hero.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/list.png" alt="bluetooth-revamped：list"><br><sub><code>list</code>，來自 <code>hero.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/json.png" alt="bluetooth-revamped：list --json"><br><sub><code>list --json</code>，來自 <code>hero.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/menu.png" alt="bluetooth-revamped：選單"><br><sub>選單，來自 <code>hero.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/menu-list.png" alt="bluetooth-revamped：從選單查看裝置"><br><sub>從選單查看裝置，來自 <code>hero.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/status-command.png" alt="bluetooth-revamped：status count 和 status min"><br><sub><code>status count</code> 和 <code>status min</code>，來自 <code>stills.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/options.png" alt="bluetooth-revamped：分隔符、格式和圖示選項"><br><sub>分隔符、格式和圖示選項，來自 <code>stills.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/refresh.png" alt="bluetooth-revamped：refresh"><br><sub><code>refresh</code>，來自 <code>stills.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/doctor.png" alt="bluetooth-revamped：doctor"><br><sub><code>doctor</code>，來自 <code>stills.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/plain-menu.png" alt="bluetooth-revamped：沒有 gum 時的選單"><br><sub>沒有 gum 時的選單，來自 <code>stills.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/plain-doctor.png" alt="bluetooth-revamped：沒有 gum 時的 doctor，使用 macOS 內建的工具"><br><sub>沒有 gum 時的 doctor，使用 macOS 內建的工具，來自 <code>stills.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/version.png" alt="bluetooth-revamped：版本"><br><sub>版本，來自 <code>stills.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/error.png" alt="bluetooth-revamped：錯誤的佔位符名稱"><br><sub>錯誤的佔位符名稱，來自 <code>stills.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/accent.png" alt="bluetooth-revamped：來自 BLUETOOTH_REVAMPED_ACCENT 的強調色"><br><sub>來自 <code>BLUETOOTH_REVAMPED_ACCENT</code> 的強調色，來自 <code>stills.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/popup.png" alt="bluetooth-revamped：prefix M-h 上的裝置彈出視窗"><br><sub><code>prefix M-h</code> 上的裝置彈出視窗，來自 <code>actions.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/connect.png" alt="bluetooth-revamped：從彈出視窗連接的裝置"><br><sub>從彈出視窗連接的裝置，來自 <code>actions.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/icons.png" alt="bluetooth-revamped：每種裝置類型的字形"><br><sub>每種裝置類型的字形，來自 <code>actions.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/power.png" alt="bluetooth-revamped：power toggle 和 disconnect"><br><sub><code>power toggle</code> 和 <code>disconnect</code>，來自 <code>actions.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/themes.png" alt="bluetooth-revamped：六個主題下的標題"><br><sub>六個主題下的標題，來自 <code>themes.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/help.png" alt="bluetooth-revamped：說明頁面"><br><sub>說明頁面，來自 <code>help.tape</code></sub></td>
</tr>
</table>

</details>

## 可攜性

插件是 POSIX `sh`。CI 在下列每一行上執行全部測試。

| Shell | 狀態 |
|:------|:-------|
| `dash`、macOS 上的 `/bin/sh` | 支援 |
| `bash` 3.2 和 5.x、系統內建的 `zsh` 和 Homebrew 的 `zsh` | 支援 |

| 系統 | 狀態 |
|:-------|:-------|
| macOS | Apple Silicon 和 Intel 上的 Tahoe，使用內建的工具、Homebrew 的 GNU 工具和 Homebrew 的 uutils |
| Linux | x86_64 和 arm64 上的 Ubuntu 26.04，使用 GNU coreutils、uutils 和 BusyBox |
| FreeBSD、OpenBSD、NetBSD | 不在 CI 涵蓋範圍內；佔位符為空，`doctor` 說明沒有讀取來源 |

## 開發

| 指令 | 執行內容 |
|:--------|:-------------|
| `make fmt` | 對每個腳本執行 shfmt `-i 2` |
| `make lint` | shfmt、ShellCheck、mandoc、yamllint 和 actionlint，零警告 |
| `make test` | 在系統 `sh` 下執行 bats 測試 |
| `make test-all` | 在每個已安裝的 shell 下執行測試，macOS 上包括 bash 和 zsh 的兩種版本 |
| `make test-linux` | 在 Ubuntu 容器中執行測試 |
| `make coverage` | 在這部 Mac 和 Ubuntu 容器中執行 bashcov，合併後以 100% 為門檻 |
| `make screens` | 以 VHS 在 tmux 中從真實插件錄製上述畫面，在 macOS 上執行 |
| `make install` | 把指令、man 手冊和自動完成安裝到 `PREFIX` 下 |

提交遵循 Conventional Commits 格式，直接進入 `main`。`main` 上的 `ci` 通過後，`release.yml` 會執行 semantic-release：自上一個標籤以來的每個 `feat` 或 `fix` 都會發佈新版本，更新版本常數，並把說明寫入 [`CHANGELOG.md`](CHANGELOG.md)。

## 授權

[MIT](LICENSE)，copyright Gustavo Franco。

<!-- family:begin -->

## tmux-revamped 插件家族

這個插件是 tmux-revamped 插件家族的一員。每個成員都帶有 [`FAMILY.md`](FAMILY.md) 中相同的約定和相同的共用程式庫，並且設計為一起安裝：沒有成員佔用另一個成員佔用的按鍵或 tmux 選項。

在一個成員中發現的缺陷，要在全部成員中排查後才算修正完成。

| 成員 | 功能 |
|---|---|
| [`tmux-autoreload-revamped`](https://github.com/tmux-revamped/tmux-autoreload-revamped) | 編輯並儲存 tmux 設定後，它會自動重新載入，毋須按鍵，也毋須指令 |
| [`tmux-battery-revamped`](https://github.com/tmux-revamped/tmux-battery-revamped) | 在 tmux 狀態列顯示電池狀態，從不阻塞狀態列繪製 |
| [`tmux-bluetooth-revamped`](https://github.com/tmux-revamped/tmux-bluetooth-revamped) | **本插件**，在 tmux 狀態列顯示每部已連接的藍牙裝置及其電量，不阻塞繪製 |
| [`tmux-cpu-revamped`](https://github.com/tmux-revamped/tmux-cpu-revamped) | 在 tmux 狀態列顯示 CPU 負載、溫度及頻率，從不阻塞繪製 |
| [`tmux-disk-revamped`](https://github.com/tmux-revamped/tmux-disk-revamped) | 在 tmux 狀態列顯示磁碟用量，從不阻塞狀態列繪製 |
| [`tmux-extract-revamped`](https://github.com/tmux-revamped/tmux-extract-revamped) | 用 fzf 從畫面上揀選 URL、路徑、雜湊值或任何其他字詞，並輸入到游標位置，全部以純 shell 實現 |
| [`tmux-fzf-revamped`](https://github.com/tmux-revamped/tmux-fzf-revamped) | 在彈出視窗的 fzf 選擇器中切換、關閉、重新命名或建立 tmux 工作階段、視窗和窗格 |
| [`tmux-git-revamped`](https://github.com/tmux-revamped/tmux-git-revamped) | 在 tmux 狀態列顯示當前窗格的 git 分支、改動和託管平台數目，而不會阻塞顯示 |
| [`tmux-gpu-revamped`](https://github.com/tmux-revamped/tmux-gpu-revamped) | 在 tmux 狀態列顯示 NVIDIA、AMD、Intel 及 Apple GPU 的負載、溫度、時脈、功耗及記憶體 |
| [`tmux-kube-revamped`](https://github.com/tmux-revamped/tmux-kube-revamped) | 在 tmux 狀態列顯示目前的 Kubernetes 上下文及命名空間，毋須 kubectl，直接解析 kubeconfig |
| [`tmux-launcher-revamped`](https://github.com/tmux-revamped/tmux-launcher-revamped) | 在彈出視窗或新視窗中啟動任何 TUI 應用程式，從目前窗格的目錄開始，每個應用程式可設定一個按鍵 |
| [`tmux-logging-revamped`](https://github.com/tmux-revamped/tmux-logging-revamped) | 將任何窗格儲存到檔案：即時記錄、完整捲動緩衝區或一次性截圖 |
| [`tmux-music-revamped`](https://github.com/tmux-revamped/tmux-music-revamped) | 在 tmux 狀態列顯示正在播放的歌曲，從不阻塞狀態列的繪製 |
| [`tmux-network-revamped`](https://github.com/tmux-revamped/tmux-network-revamped) | 在 tmux 狀態列顯示網絡傳輸量，從不阻塞繪製 |
| [`tmux-pain-control-revamped`](https://github.com/tmux-revamped/tmux-pain-control-revamped) | tmux 的窗格和視窗管理按鍵，配合 tmux 版本，與 vim 相容，每個 prefix 按鍵都可停用 |
| [`tmux-persist-revamped`](https://github.com/tmux-revamped/tmux-persist-revamped) | 儲存 tmux 的所有工作階段、視窗及窗格，按計時器自動儲存，並在重新開機後全部還原 |
| [`tmux-plugin-template`](https://github.com/tmux-revamped/tmux-plugin-template) | tmux-revamped 插件的起點：共用程式庫、bats 測試框架和 CI |
| [`tmux-pomodoro-revamped`](https://github.com/tmux-revamped/tmux-pomodoro-revamped) | tmux 狀態列中的番茄鐘計時器，所有狀態都儲存在 tmux 選項中，不使用暫存檔 |
| [`tmux-ram-revamped`](https://github.com/tmux-revamped/tmux-ram-revamped) | 在 tmux 狀態列顯示記憶體、交換空間及記憶體壓力，在背景取樣，繪製從不等待 |
| [`tmux-reorder-revamped`](https://github.com/tmux-revamped/tmux-reorder-revamped) | 用滑鼠在 tmux 狀態列上拖動視窗標籤來移動該視窗 |
| [`tmux-scroll-revamped`](https://github.com/tmux-revamped/tmux-scroll-revamped) | 將滑鼠滾輪交給能自行捲動的應用程式，其他情況下進入 tmux 複製模式 |
| [`tmux-sensible-revamped`](https://github.com/tmux-revamped/tmux-sensible-revamped) | 按 tmux 版本和終端機區分的合理預設設定，不會改動你自己設定的選項 |
| [`tmux-tiling-revamped`](https://github.com/tmux-revamped/tmux-tiling-revamped) | tmux 的平鋪視窗管理：八種版面，包括 BSP dwindle 和 spiral，並支援復原版面 |
| [`tmux-time-revamped`](https://github.com/tmux-revamped/tmux-time-revamped) | 狀態列中的本地時鐘和世界時鐘，按一天中的時段著色，並提供倒數和夏令時間提示 |
| [`tmux-weather-revamped`](https://github.com/tmux-revamped/tmux-weather-revamped) | 在背景從 wttr.in 取得天氣並顯示在狀態列，狀態列毋須等待 |

<!-- family:end -->
