<div align="center">

# tmux-bluetooth-revamped

<strong>在 tmux 狀態列顯示每部已連接的藍牙裝置及其電量，不阻塞繪製。</strong>

[English](README.md) &nbsp;|&nbsp; [日本語](README.ja.md) &nbsp;|&nbsp; [简体中文](README.zh-Hans.md) &nbsp;|&nbsp; 繁體中文（香港）

[![Tests](https://github.com/tmux-revamped/tmux-bluetooth-revamped/actions/workflows/tests.yml/badge.svg)](https://github.com/tmux-revamped/tmux-bluetooth-revamped/actions/workflows/tests.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-1.2.0-blue.svg)](CHANGELOG.md)

<p align="center">
  <a href="#what-it-does">功能</a> &nbsp;|&nbsp;
  <a href="#requirements">系統要求</a> &nbsp;|&nbsp;
  <a href="#installation">安裝</a> &nbsp;|&nbsp;
  <a href="#usage">用法</a> &nbsp;|&nbsp;
  <a href="#configuration">設定</a> &nbsp;|&nbsp;
  <a href="#key-bindings">快捷鍵</a> &nbsp;|&nbsp;
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

這個插件是 tmux-revamped 插件家族的一員。每個成員都帶有 [`FAMILY.md`](FAMILY.md) 中相同的約定、`family/` 下相同的工具及相同的共用程式庫，並由校驗和清單保持逐位元組一致。它們以一同安裝為設計前提：任何成員都不會佔用其他成員已佔用的按鍵或 tmux 選項。

在一個成員中發現的缺陷，要在所有成員中排查之後，修正才算完成。這項責任寫在約定之中，而不是靠記憶，並透過 `family/bin/sweep` 履行。

| 成員 | 功能 |
|---|---|
| [`tmux-autoreload-revamped`](https://github.com/tmux-revamped/tmux-autoreload-revamped) | 編輯並儲存 tmux 設定後自動重新載入，毋須按鍵，也毋須指令 |
| [`tmux-battery-revamped`](https://github.com/tmux-revamped/tmux-battery-revamped) | 在 tmux 狀態列顯示電池狀態，從不阻塞狀態列繪製 |
| [`tmux-bluetooth-revamped`](https://github.com/tmux-revamped/tmux-bluetooth-revamped) | **本插件**，在 tmux 狀態列顯示每部已連接的藍牙裝置及其電量，不阻塞繪製 |
| [`tmux-cpu-revamped`](https://github.com/tmux-revamped/tmux-cpu-revamped) | 在 tmux 狀態列顯示 CPU 負載、溫度及頻率，從不阻塞繪製 |
| [`tmux-disk-revamped`](https://github.com/tmux-revamped/tmux-disk-revamped) | 在 tmux 狀態列顯示磁碟用量，從不阻塞狀態列繪製 |
| [`tmux-extract-revamped`](https://github.com/tmux-revamped/tmux-extract-revamped) | 以 fzf 從螢幕上揀選 URL、路徑、雜湊或其他片段，並在游標處輸入，純 shell 實作 |
| [`tmux-fzf-revamped`](https://github.com/tmux-revamped/tmux-fzf-revamped) | 在彈出視窗的 fzf 選擇器中切換、關閉、重新命名或新增 tmux 工作階段、視窗及窗格 |
| [`tmux-git-revamped`](https://github.com/tmux-revamped/tmux-git-revamped) | 在 tmux 狀態列顯示目前窗格的 git 分支、改動及託管平台計數，不阻塞狀態列 |
| [`tmux-gpu-revamped`](https://github.com/tmux-revamped/tmux-gpu-revamped) | 在 tmux 狀態列顯示 NVIDIA、AMD、Intel 及 Apple GPU 的負載、溫度、時脈、功耗及記憶體 |
| [`tmux-kube-revamped`](https://github.com/tmux-revamped/tmux-kube-revamped) | 不借助 kubectl，從 kubeconfig 解析目前的 Kubernetes 環境及命名空間，顯示在 tmux 狀態列 |
| [`tmux-launcher-revamped`](https://github.com/tmux-revamped/tmux-launcher-revamped) | 在彈出視窗或視窗中啟動任何 TUI 應用程式，工作目錄為目前窗格的目錄，按鍵可設定 |
| [`tmux-logging-revamped`](https://github.com/tmux-revamped/tmux-logging-revamped) | 把任何窗格儲存到檔案：即時記錄、完整回捲記錄或單次截圖 |
| [`tmux-music-revamped`](https://github.com/tmux-revamped/tmux-music-revamped) | 在 tmux 狀態列顯示正在播放的曲目，從不阻塞狀態列繪製 |
| [`tmux-network-revamped`](https://github.com/tmux-revamped/tmux-network-revamped) | 在 tmux 狀態列顯示網絡吞吐量，從不阻塞繪製 |
| [`tmux-pain-control-revamped`](https://github.com/tmux-revamped/tmux-pain-control-revamped) | tmux 的標準窗格及視窗管理快捷鍵，按版本調整，貼合 vim 習慣，全部可設定 |
| [`tmux-persist-revamped`](https://github.com/tmux-revamped/tmux-persist-revamped) | 儲存所有 tmux 工作階段、視窗及窗格，定時自動儲存，並在重新開機後全部還原 |
| [`tmux-plugin-template`](https://github.com/tmux-revamped/tmux-plugin-template) | tmux-revamped 插件的起點：共用程式庫、bats 測試框架、CI 及家族工具 |
| [`tmux-pomodoro-revamped`](https://github.com/tmux-revamped/tmux-pomodoro-revamped) | 顯示在 tmux 狀態列的番茄鐘，所有狀態都儲存在 tmux 選項中，不使用暫存檔 |
| [`tmux-ram-revamped`](https://github.com/tmux-revamped/tmux-ram-revamped) | 在 tmux 狀態列顯示記憶體、交換空間及記憶體壓力，在背景取樣，繪製從不等待 |
| [`tmux-reorder-revamped`](https://github.com/tmux-revamped/tmux-reorder-revamped) | 以滑鼠沿 tmux 狀態列拖動視窗標籤，以移動該視窗 |
| [`tmux-scroll-revamped`](https://github.com/tmux-revamped/tmux-scroll-revamped) | 把滑鼠滾輪交給能自行捲動的應用程式，其他情況下進入 tmux 複製模式 |
| [`tmux-sensible-revamped`](https://github.com/tmux-revamped/tmux-sensible-revamped) | 按 tmux 版本及終端機啟用的合理預設設定，不改動你自行設定的選項 |
| [`tmux-tiling-revamped`](https://github.com/tmux-revamped/tmux-tiling-revamped) | tmux 的平鋪視窗管理：8 種版面，包括 BSP 的 dwindle 及 spiral，並支援還原版面 |
| [`tmux-time-revamped`](https://github.com/tmux-revamped/tmux-time-revamped) | 在 tmux 狀態列顯示本地時鐘及世界時鐘，按時段著色，附倒數及夏令時間提示 |
| [`tmux-weather-revamped`](https://github.com/tmux-revamped/tmux-weather-revamped) | 在 tmux 狀態列顯示來自 wttr.in 的天氣，在背景擷取，狀態列從不等待 |

### 檢查安裝

所有成員都在磁碟上時，一個指令即可報告它們之間的衝突：

```sh
family/bin/doctor --live
```

它讀取每個成員及正在運行的 tmux 伺服器，報告重複的按鍵、重複的狀態列佔位符、不符合命名規則的選項，以及約定版本落後的成員。

<!-- family:end -->
