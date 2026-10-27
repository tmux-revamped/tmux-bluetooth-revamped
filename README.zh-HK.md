<div align="center">

# tmux-bluetooth-revamped

<strong>在 tmux 狀態列顯示每部已連接的藍牙裝置及其電量，不阻塞繪製。</strong>

[English](README.md) | [日本語](README.ja.md) | [简体中文](README.zh-Hans.md) | 繁體中文（香港）

[![Tests](https://github.com/tmux-revamped/tmux-bluetooth-revamped/actions/workflows/tests.yml/badge.svg)](https://github.com/tmux-revamped/tmux-bluetooth-revamped/actions/workflows/tests.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-1.2.1-blue.svg)](CHANGELOG.md)

<p align="center">
  <a href="#what-it-does">功能</a> |
  <a href="#requirements">系統要求</a> |
  <a href="#installation">安裝</a> |
  <a href="#usage">用法</a> |
  <a href="#configuration">設定</a> |
  <a href="#key-bindings">快捷鍵</a> |
  <a href="#how-it-works">運作原理</a>
</p>

</div>

**4** 個佔位符。**4** 個選項。預設每 **30** 秒查詢一次裝置。CI 在 **10** 種 Linux 及 macOS 工具鏈組合上執行測試。

---

<a id="what-it-does"></a>

## 功能

插件把 `status-left` 及 `status-right` 中的 `#{bluetooth*}` 佔位符替換為已連接的藍牙裝置及其電量，例如 `AirPods 85%, MX Master 50%`。狀態列讀取快取在 tmux 選項中的值，裝置查詢在背景進行。不會寫入任何內容到磁碟。

- 不報告電量的裝置只顯示名稱。
- 報告左耳、右耳及充電盒電量的 AirPods 只列出一次，顯示兩隻耳機中較低的電量。
- 在 Linux 上只列出藍牙裝置，因此不會出現手提電腦電池。
- 沒有裝置連接時，裝置清單及圖示顯示為空，數目顯示為 `0`。

<a id="requirements"></a>

## 系統要求

| 工具 | 版本 | 用途 |
|:-----|:--------|:-----------|
| tmux | 3.2 或以上 | 插件家族的最低版本 |
| bash | 3.2 或以上 | 所有腳本，包括 macOS 的 `/bin/bash` |
| `upower` | 任何 | 只限 Linux，裝置清單 |

| 平台 | 資料來源 |
|:---------|:-------|
| macOS，Intel 及 Apple Silicon | 系統內置的 `system_profiler SPBluetoothDataType` |
| Linux，x86_64 及 arm64 | `upower --dump` |

<a id="installation"></a>

## 安裝

### 使用 TPM

把插件及佔位符加入 `~/.tmux.conf`，然後按 `prefix + I`：

```tmux
set -g @plugin 'tmux-revamped/tmux-bluetooth-revamped'
set -g status-right '#{bluetooth_icon} #{bluetooth}'
```

### 手動安裝

```bash
git clone https://github.com/tmux-revamped/tmux-bluetooth-revamped ~/.tmux/plugins/tmux-bluetooth-revamped
```

然後把這一行加到 `~/.tmux.conf` 中設定 `status-left` 及 `status-right` 的行之後，並重新載入 tmux：

```tmux
run-shell ~/.tmux/plugins/tmux-bluetooth-revamped/bluetooth-revamped.tmux
```

<a id="usage"></a>

## 用法

在 `status-left` 或 `status-right` 中寫入佔位符，插件載入時會替換它們。完整範例見 [`examples/status-right.tmux.conf`](examples/status-right.tmux.conf)。

| 佔位符 | 輸出 |
|:------------|:-------|
| `#{bluetooth}` | 每部已連接的裝置及其電量，例如 `AirPods 85%, MX Master 50%` |
| `#{bluetooth_icon}` | 有裝置連接時為 `@bluetooth_revamped_icon`，否則為空 |
| `#{bluetooth_count}` | 已連接裝置的數目，例如 `2` |
| `#{bluetooth_min}` | 電量最低的裝置，例如 `MX Master 50%`；沒有裝置報告電量時為空 |

<a id="configuration"></a>

## 設定

| 選項 | 預設值 | 意思 |
|:-------|:--------|:--------|
| `@bluetooth_revamped_interval` | `30` | 裝置讀數保持有效的秒數；不是數字的值會改用 `30` |
| `@bluetooth_revamped_format` | `%s` | `#{bluetooth}` 的 printf 格式 |
| `@bluetooth_revamped_separator` | `, ` | `#{bluetooth}` 中裝置之間的文字 |
| `@bluetooth_revamped_icon` | `BT` | `#{bluetooth_icon}` 的文字 |

```tmux
set -g @bluetooth_revamped_separator ' | '
set -g @bluetooth_revamped_format '[%s]'
```

### 內部狀態

以下選項由插件自行寫入，請勿設定。

| 選項 | 內容 |
|:-------|:------|
| `@bluetooth_revamped_device` | 快取的裝置清單，每行一部裝置 |
| `@bluetooth_revamped_device_ts`、`@bluetooth_revamped_device_lock` | 讀取清單的時間，以及是否正在更新 |

<a id="key-bindings"></a>

## 快捷鍵

插件不綁定任何按鍵。

<a id="how-it-works"></a>

## 運作原理

每個佔位符都會變成呼叫 [`src/bluetooth.sh`](src/bluetooth.sh) 的 `#()`。呼叫會立即輸出快取的裝置清單。當清單比 `@bluetooth_revamped_interval` 秒舊時，它亦會啟動一次背景更新；更新受鎖保護，並行的呼叫不會再啟動第二次。下一次重繪狀態列時便會顯示新的清單。

<a id="development"></a>

## 開發

| 指令 | 執行內容 |
|:--------|:-------------|
| `make test` | [`test/`](test) 下的 bats 測試 |
| `make lint` | 對所有 shell 檔案執行 shellcheck |
| `make coverage` | 在 Linux 上以 kcov 計算行覆蓋率，低於 95% 時失敗 |

<a id="license"></a>

## 授權

[MIT](LICENSE)，copyright Gustavo Franco。

<!-- family:begin -->

## tmux-revamped 插件家族

本插件是 tmux-revamped 插件家族的成員。每個成員都帶有 [`FAMILY.md`](FAMILY.md) 中的同一份約定、`family/` 下的同一套工具和同一個共用程式庫，並由校驗和清單確保逐位元組一致。這些成員可以一併安裝：任何成員都不會佔用其他成員使用的按鍵或 tmux 選項。

在一個成員中發現的缺陷，要在全部成員中排查後才算修正完成。這項責任寫在約定之中，而不是依靠記憶，`family/bin/sweep` 負責執行。

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
| [`tmux-plugin-template`](https://github.com/tmux-revamped/tmux-plugin-template) | tmux-revamped 插件的起點：共用程式庫、bats 測試框架、CI 和系列工具 |
| [`tmux-pomodoro-revamped`](https://github.com/tmux-revamped/tmux-pomodoro-revamped) | tmux 狀態列中的番茄鐘計時器，所有狀態都儲存在 tmux 選項中，不使用暫存檔 |
| [`tmux-ram-revamped`](https://github.com/tmux-revamped/tmux-ram-revamped) | 在 tmux 狀態列顯示記憶體、交換空間及記憶體壓力，在背景取樣，繪製從不等待 |
| [`tmux-reorder-revamped`](https://github.com/tmux-revamped/tmux-reorder-revamped) | 用滑鼠在 tmux 狀態列上拖動視窗標籤來移動該視窗 |
| [`tmux-scroll-revamped`](https://github.com/tmux-revamped/tmux-scroll-revamped) | 將滑鼠滾輪交給能自行捲動的應用程式，其他情況下進入 tmux 複製模式 |
| [`tmux-sensible-revamped`](https://github.com/tmux-revamped/tmux-sensible-revamped) | 按 tmux 版本和終端機區分的合理預設設定，不會改動你自己設定的選項 |
| [`tmux-tiling-revamped`](https://github.com/tmux-revamped/tmux-tiling-revamped) | tmux 的平鋪視窗管理：八種版面，包括 BSP dwindle 和 spiral，並支援復原版面 |
| [`tmux-time-revamped`](https://github.com/tmux-revamped/tmux-time-revamped) | 狀態列中的本地時鐘和世界時鐘，按一天中的時段著色，並提供倒數和夏令時間提示 |
| [`tmux-weather-revamped`](https://github.com/tmux-revamped/tmux-weather-revamped) | 在背景從 wttr.in 取得天氣並顯示在狀態列，狀態列毋須等待 |

### 檢查安裝

所有成員都在磁碟上時，一個指令即可報告它們之間的任何衝突：

```sh
family/bin/doctor --live
```

它讀取每個成員和正在運行的 tmux 伺服器，報告重複的按鍵、重複的狀態佔位符、不符合命名規則的選項，以及約定版本落後的成員。

<!-- family:end -->
