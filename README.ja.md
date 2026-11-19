<div align="center">

# tmux-bluetooth-revamped

<strong>接続中のすべてのBluetooth機器とその電池残量をtmuxのステータスバーに表示し、描画を止めません。</strong>

[English](README.md) &nbsp;|&nbsp; 日本語 &nbsp;|&nbsp; [简体中文](README.zh-Hans.md) &nbsp;|&nbsp; [繁體中文（香港）](README.zh-HK.md)

[![ci](https://img.shields.io/github/actions/workflow/status/tmux-revamped/tmux-bluetooth-revamped/ci.yml?branch=main&style=flat-square&label=ci)](https://github.com/tmux-revamped/tmux-bluetooth-revamped/actions/workflows/ci.yml)
[![release](https://img.shields.io/github/v/release/tmux-revamped/tmux-bluetooth-revamped?style=flat-square&label=release)](https://github.com/tmux-revamped/tmux-bluetooth-revamped/releases/latest)
[![openssf scorecard](https://img.shields.io/ossf-scorecard/github.com/tmux-revamped/tmux-bluetooth-revamped?style=flat-square&label=openssf%20scorecard)](https://scorecard.dev/viewer/?uri=github.com/tmux-revamped/tmux-bluetooth-revamped)
[![license](https://img.shields.io/github/license/tmux-revamped/tmux-bluetooth-revamped?style=flat-square&label=license)](LICENSE)

<p align="center">
  <a href="#クイックスタート"><strong>クイックスタート</strong></a> &nbsp;|&nbsp;
  <a href="#使い方">使い方</a> &nbsp;|&nbsp;
  <a href="#仕組み">仕組み</a> &nbsp;|&nbsp;
  <a href="#画面">画面</a>
</p>

</div>

<p align="center">
  <img src="screens/hero.gif" alt="ステータスラインに3台のBluetooth機器を表示するtmux。続いてbluetooth-revamped listとメニュー" width="800">
</p>

```console
$ bluetooth-revamped list
AirPods Pro 85%
MX Master 3S 50%
```

ステータスラインはtmuxのオプションに保存した読み取り結果を表示し、機器の問い合わせはバックグラウンドで行います。そのためBluetoothの応答が遅くてもtmuxは止まりません。ディスクには何も書きません。

---

## クイックスタート

### 前提条件

| ツール | バージョン | 用途 |
|:-----|:--------|:---------|
| tmux | 3.2以降 | ファミリーの全メンバーが対応する最低バージョン |
| `system_profiler` | 標準搭載 | macOSの機器一覧。IntelとApple Silicon |
| `upower` | 任意 | Linuxの機器一覧。x86_64とarm64 |
| `blueutil` | 任意 | macOSでの接続、切断、電源。`brew install blueutil`で入ります |
| `bluetoothctl` | 任意 | Linuxでの接続、切断、電源、ペアリング済み機器の一覧。`bluez`パッケージに含まれます |
| gum | 任意 | `bluetooth-revamped`のメニュー、表、色。なくてもすべてのコマンドがプレーンテキストで動きます |

### インストール

`~/.tmux.conf`にプラグインとプレースホルダーを追加し、`prefix + I`を押します。

```tmux
set -g @plugin 'tmux-revamped/tmux-bluetooth-revamped'
set -g status-right '#{bluetooth_icon} #{bluetooth}'
```

TPMを使わない場合は、リポジトリをクローンし、`status-left`と`status-right`を設定する行のあとでエントリーポイントを読み込みます。

```bash
git clone https://github.com/tmux-revamped/tmux-bluetooth-revamped ~/.tmux/plugins/tmux-bluetooth-revamped
```

```tmux
run-shell ~/.tmux/plugins/tmux-bluetooth-revamped/bluetooth-revamped.tmux
```

クローンで`make install`を実行すると、`bluetooth-revamped`が`~/.local/bin`に、manページとbash、zsh、fishの補完が`~/.local/share`の下に入ります。

### 確認

```bash
~/.tmux/plugins/tmux-bluetooth-revamped/bin/bluetooth-revamped doctor
```

`doctor`はツールごとに1行を表示し、見つかった機器の読み取り元を示します。終了コードが1になるのは、必須のツールが見つからないときだけです。

## 使い方

| プレースホルダー | 出力 |
|:------------|:-------|
| `#{bluetooth}` | 接続中のすべての機器と電池残量。`AirPods Pro 85%, MX Master 3S 50%`など |
| `#{bluetooth_icon}` | 機器の接続中は`@bluetooth_revamped_icon`、それ以外は空 |
| `#{bluetooth_count}` | 接続中の機器の数。`2`など |
| `#{bluetooth_min}` | 電池残量がいちばん少ない機器。`MX Master 3S 50%`など。どの機器も残量を報告しないときは空 |

| tmuxオプション | 既定値 | 意味 |
|:------------|:--------|:--------|
| `@bluetooth_revamped_interval` | `30` | 読み取り結果が新しいとみなされる秒数。数値でない値は`30`になります |
| `@bluetooth_revamped_format` | `%s` | `#{bluetooth}`のprintf形式 |
| `@bluetooth_revamped_separator` | `, ` | `#{bluetooth}`で機器の間に入る文字列 |
| `@bluetooth_revamped_icon` | `BT` | `#{bluetooth_icon}`の文字列 |
| `@bluetooth_revamped_icons` | `0` | `1`で`#{bluetooth}`の各機器の前に種類を表すNerd Fontのグリフを置きます |
| `@bluetooth_revamped_notify` | `0` | `1`で、接続中の機器の電池残量が低い水準を下回るとデスクトップ通知を送ります |
| `@bluetooth_revamped_low` | `20` | 電池残量が低いとみなすパーセント |
| `@bluetooth_revamped_popup_key` | `M-h` | 機器ポップアップを開くprefixキー。`none`で割り当てません |

```tmux
set -g @bluetooth_revamped_separator ' / '
set -g @bluetooth_revamped_format '[%s]'
```

| コマンド | 動作 |
|:--------|:-------------|
| `bluetooth-revamped status NAME` | プレースホルダーを1つ表示します。`device`、`icon`、`count`、`min`のいずれか。プレースホルダーはこれを呼びます |
| `bluetooth-revamped list` | 機器をいま読み取り、1行に1台ずつ表示します。`--json`で1つのオブジェクトを出力します |
| `bluetooth-revamped refresh` | ステータスラインのために機器をいま読み取ります |
| `bluetooth-revamped connect DEVICE` | ペアリング済みの機器を名前かアドレスで指定して接続します |
| `bluetooth-revamped disconnect DEVICE` | 機器を切断します |
| `bluetooth-revamped power on\|off\|toggle` | Bluetoothをオンかオフにするか、切り替えます |
| `bluetooth-revamped popup` | 機器の表を表示し、接続、切断、電源の切り替えを選べます。`prefix M-h`で開きます |
| `bluetooth-revamped doctor` | 依存するツールごとに1行。機器の読み取り元を含みます |
| `bluetooth-revamped version` | バージョンと、tmuxのバージョン |
| `bluetooth-revamped help` | ヘルプページ。`man bluetooth-revamped`も同じコマンドと設定を説明します |
| `bluetooth-revamped` | 端末ではメニューを表示します。機器の表示、このマシンの確認、ヘルプを選べます |

tmuxオプションはどれも、`--separator ' / '`のようなコマンドのオプションとしても、`BLUETOOTH_REVAMPED_SEPARATOR`のような環境変数としても指定できます。コマンドラインが環境変数に優先し、環境変数がtmuxオプションに優先します。空のtmuxオプションは既定値を意味します。`doctor` は、プラグインが認識できない値を持つ設定の名前を表示します。`--theme NAME`、`BLUETOOTH_REVAMPED_THEME`、`BLUETOOTH_REVAMPED_ACCENT`、`KODOUGU_THEME`、`KODOUGU_ACCENT`、`NO_COLOR`、tmuxオプション`@revamped_theme`は、tmux-revampedのすべてのツールと同じくコマンドの見た目を決めます。

```console
$ bluetooth-revamped list --json
{"devices":[{"name":"AirPods Pro","battery":85},{"name":"MX Master 3S","battery":50}]}
```

`prefix M-h`で機器ポップアップが開きます。`@bluetooth_revamped_popup_key`で別のキーに移せ、`none`では何も割り当てません。プラグインの読み込み前に自分で割り当てたキーはそのまま残り、`doctor`がそのことを示します。

電池残量が低くなると通知は1回だけ送られ、水準を上回ったあとにまた下がったときに再び送られます。`@bluetooth_revamped_notify`を`1`にするまで通知はオフで、同じ状態はいつでも`#{bluetooth_min}`に表示されます。

## 仕組み

tmuxがプラグインを読み込むと、[`bluetooth-revamped.tmux`](bluetooth-revamped.tmux)が`status-left`と`status-right`の各プレースホルダーを`bluetooth-revamped status`を呼ぶ`#()`に置き換えます。この呼び出しは`@bluetooth_revamped_device`に保存した読み取り結果をすぐに表示します。結果が間隔より古いと、バックグラウンドで読み取りを1回始めます。`@bluetooth_revamped_device_lock`のロックがあるので、同時の呼び出しが2回目を始めることはなく、次の再描画で結果が表示されます。

読み取りのたびに、ペアリング済みのすべての機器の状態、アドレス、種類、電池残量も`@bluetooth_revamped_details`に保存します。ポップアップ、操作、アイコンはこれを読みます。

macOSは`system_profiler SPBluetoothDataType`を読み、`blueutil`で操作します。Linuxは`bluetoothctl`でペアリング済み機器を一覧し、それで操作します。AirPodsは左右のイヤホンとケースの残量を報告し、プラグインはイヤホンの低いほうを表示します。Linuxは`upower --dump`を読みます。Bluetooth機器だけを数えるので、ノートパソコンの電池は表示されません。

<a id="画面"></a>

## 画面

<details>
<summary><code>make screens</code>で本物のtmuxの中から録画したすべての画面。押したキーはステータスラインに表示されます</summary>
<br>

<table>
<tr>
<td width="50%" valign="top"><img src="screens/status.png" alt="bluetooth-revamped: ステータスラインのすべてのプレースホルダー"><br><sub>ステータスラインのすべてのプレースホルダー。<code>hero.tape</code>より</sub></td>
<td width="50%" valign="top"><img src="screens/list.png" alt="bluetooth-revamped: list"><br><sub><code>list</code>。<code>hero.tape</code>より</sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/json.png" alt="bluetooth-revamped: list --json"><br><sub><code>list --json</code>。<code>hero.tape</code>より</sub></td>
<td width="50%" valign="top"><img src="screens/menu.png" alt="bluetooth-revamped: メニュー"><br><sub>メニュー。<code>hero.tape</code>より</sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/menu-list.png" alt="bluetooth-revamped: メニューからの機器一覧"><br><sub>メニューからの機器一覧。<code>hero.tape</code>より</sub></td>
<td width="50%" valign="top"><img src="screens/status-command.png" alt="bluetooth-revamped: status countとstatus min"><br><sub><code>status count</code>と<code>status min</code>。<code>stills.tape</code>より</sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/options.png" alt="bluetooth-revamped: 区切り、形式、アイコンのオプション"><br><sub>区切り、形式、アイコンのオプション。<code>stills.tape</code>より</sub></td>
<td width="50%" valign="top"><img src="screens/refresh.png" alt="bluetooth-revamped: refresh"><br><sub><code>refresh</code>。<code>stills.tape</code>より</sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/doctor.png" alt="bluetooth-revamped: doctor"><br><sub><code>doctor</code>。<code>stills.tape</code>より</sub></td>
<td width="50%" valign="top"><img src="screens/plain-menu.png" alt="bluetooth-revamped: gumなしのメニュー"><br><sub>gumなしのメニュー。<code>stills.tape</code>より</sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/plain-doctor.png" alt="bluetooth-revamped: gumなしのdoctor。macOS付属のツールで実行"><br><sub>gumなしのdoctor。macOS付属のツールで実行。<code>stills.tape</code>より</sub></td>
<td width="50%" valign="top"><img src="screens/version.png" alt="bluetooth-revamped: バージョン"><br><sub>バージョン。<code>stills.tape</code>より</sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/error.png" alt="bluetooth-revamped: 誤ったプレースホルダー名"><br><sub>誤ったプレースホルダー名。<code>stills.tape</code>より</sub></td>
<td width="50%" valign="top"><img src="screens/accent.png" alt="bluetooth-revamped: BLUETOOTH_REVAMPED_ACCENTによるアクセント"><br><sub><code>BLUETOOTH_REVAMPED_ACCENT</code>によるアクセント。<code>stills.tape</code>より</sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/popup.png" alt="bluetooth-revamped: prefix M-hの機器ポップアップ"><br><sub><code>prefix M-h</code>の機器ポップアップ。<code>actions.tape</code>より</sub></td>
<td width="50%" valign="top"><img src="screens/connect.png" alt="bluetooth-revamped: ポップアップからの接続"><br><sub>ポップアップからの接続。<code>actions.tape</code>より</sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/icons.png" alt="bluetooth-revamped: 機器の種類ごとのグリフ"><br><sub>機器の種類ごとのグリフ。<code>actions.tape</code>より</sub></td>
<td width="50%" valign="top"><img src="screens/power.png" alt="bluetooth-revamped: power toggleとdisconnect"><br><sub><code>power toggle</code>と<code>disconnect</code>。<code>actions.tape</code>より</sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/themes.png" alt="bluetooth-revamped: 6つのテーマのヘッダー"><br><sub>6つのテーマのヘッダー。<code>themes.tape</code>より</sub></td>
<td width="50%" valign="top"><img src="screens/help.png" alt="bluetooth-revamped: ヘルプページ"><br><sub>ヘルプページ。<code>help.tape</code>より</sub></td>
</tr>
</table>

</details>

## 移植性

プラグインはPOSIX `sh`です。CIは下の各行ですべてのテストを実行します。

| シェル | 状態 |
|:------|:-------|
| `dash`、macOSの`/bin/sh` | 対応 |
| `bash` 3.2と5.x、システムの`zsh`とHomebrewの`zsh` | 対応 |

| システム | 状態 |
|:-------|:-------|
| macOS | Apple SiliconとIntelのTahoe。付属のツール、HomebrewのGNUツール、Homebrewのuutilsで確認 |
| Linux | x86_64とarm64のUbuntu 26.04。GNU coreutils、uutils、BusyBoxで確認 |
| FreeBSD、OpenBSD、NetBSD | CIの対象外。プレースホルダーは空になり、`doctor`が読み取り元がないことを示します |

## 開発

| コマンド | 実行内容 |
|:--------|:-------------|
| `make fmt` | すべてのスクリプトにshfmt `-i 2`をかけます |
| `make lint` | shfmt、ShellCheck、mandoc、yamllint、actionlintを、指摘ゼロで通します |
| `make test` | システムの`sh`でbatsのテスト |
| `make test-all` | インストール済みのすべてのシェルでテスト。macOSではbashとzshの両方のビルドを含みます |
| `make test-linux` | Ubuntuのコンテナでテスト |
| `make coverage` | このMacとUbuntuのコンテナでbashcovを実行し、合算して100パーセントで判定します |
| `make screens` | 上の画面を、本物のプラグインからtmuxの中でVHSで録画します。macOSで実行します |
| `make install` | コマンド、manページ、補完を`PREFIX`の下に置きます |

macOS では、`brew bundle` を実行すると、これらのターゲットが使うツールがすべて [`Brewfile`](Brewfile) からインストールされます。

コミットはConventional Commitsの形式に従い、そのまま`main`に入ります。`main`で`ci`が成功すると、`release.yml`がsemantic-releaseを実行します。前回のタグ以降に`feat`か`fix`があればリリースを公開し、バージョン定数を更新し、変更内容を[`CHANGELOG.md`](CHANGELOG.md)に追加します。

## ライセンス

[MIT](LICENSE)、copyright Gustavo Franco。

<!-- family:begin -->

## tmux-revamped ファミリー

このプラグインは tmux-revamped ファミリーの一員です。すべてのメンバーが [`FAMILY.md`](FAMILY.md) の同じ規約と同じ共有ライブラリを持ちます。メンバーは一緒にインストールする前提で作られており、ほかのメンバーが使うキーや tmux オプションを使うメンバーはありません。

あるメンバーで見つかった不具合は、修正完了とする前に全メンバーで同じ不具合を探します。

| メンバー | 機能 |
|---|---|
| [`tmux-autoreload-revamped`](https://github.com/tmux-revamped/tmux-autoreload-revamped) | tmuxの設定を編集して保存するだけで、キーもコマンドも使わずに自動で再読み込みされます |
| [`tmux-battery-revamped`](https://github.com/tmux-revamped/tmux-battery-revamped) | tmuxのステータスバーに電池の状態を表示し、ステータスの描画を一切止めません |
| [`tmux-bluetooth-revamped`](https://github.com/tmux-revamped/tmux-bluetooth-revamped) | **このプラグイン**、接続中のすべてのBluetooth機器とその電池残量をtmuxのステータスバーに表示し、描画を止めません |
| [`tmux-cpu-revamped`](https://github.com/tmux-revamped/tmux-cpu-revamped) | CPUの負荷、温度、周波数をtmuxのステータスバーに表示し、描画を一切止めません |
| [`tmux-disk-revamped`](https://github.com/tmux-revamped/tmux-disk-revamped) | tmuxのステータスバーにディスク使用量を表示し、ステータスの描画を一切止めません |
| [`tmux-extract-revamped`](https://github.com/tmux-revamped/tmux-extract-revamped) | 画面上の URL、パス、ハッシュなどのトークンを fzf で選び、カーソル位置に入力します。純粋なシェルだけで動きます |
| [`tmux-fzf-revamped`](https://github.com/tmux-revamped/tmux-fzf-revamped) | ポップアップ内の fzf ピッカーから、tmux のセッション、ウィンドウ、ペインの切り替え、終了、名前変更、作成を行います |
| [`tmux-git-revamped`](https://github.com/tmux-revamped/tmux-git-revamped) | アクティブなペインのgitブランチ、変更、プロバイダーの件数を、描画を止めずにtmuxのステータスバーに表示します |
| [`tmux-gpu-revamped`](https://github.com/tmux-revamped/tmux-gpu-revamped) | NVIDIA、AMD、Intel、Apple の GPU の負荷、温度、クロック、電力、メモリを tmux のステータスバーに表示します |
| [`tmux-kube-revamped`](https://github.com/tmux-revamped/tmux-kube-revamped) | 現在の Kubernetes コンテキストと名前空間を、kubectl を使わずに kubeconfig から解析して tmux のステータスバーに表示します |
| [`tmux-launcher-revamped`](https://github.com/tmux-revamped/tmux-launcher-revamped) | 任意の TUI アプリを、現在のペインのディレクトリでポップアップまたはウィンドウとして起動します。アプリごとにキーを設定できます |
| [`tmux-logging-revamped`](https://github.com/tmux-revamped/tmux-logging-revamped) | 任意のペインをファイルに保存します。ライブのログ記録、スクロールバック全体、1 回限りのスクリーンショットに対応します |
| [`tmux-music-revamped`](https://github.com/tmux-revamped/tmux-music-revamped) | 再生中の曲をステータスバーに表示し、ステータスの描画を止めません |
| [`tmux-network-revamped`](https://github.com/tmux-revamped/tmux-network-revamped) | ネットワークのスループットをステータスバーに表示し、描画を止めません |
| [`tmux-pain-control-revamped`](https://github.com/tmux-revamped/tmux-pain-control-revamped) | tmux のペインとウィンドウの操作キー。tmux のバージョンに対応し、vim と共存でき、どの prefix キーも無効にできます |
| [`tmux-persist-revamped`](https://github.com/tmux-revamped/tmux-persist-revamped) | tmuxのすべてのセッション、ウィンドウ、ペインを保存し、タイマーで自動保存して、再起動後にすべて復元します |
| [`tmux-plugin-template`](https://github.com/tmux-revamped/tmux-plugin-template) | tmux-revampedプラグインの出発点です。共有ライブラリ、batsハーネス、CIを含みます |
| [`tmux-pomodoro-revamped`](https://github.com/tmux-revamped/tmux-pomodoro-revamped) | すべての状態をtmuxオプションに保持し、一時ファイルを使わない、tmuxステータスバーのポモドーロタイマーです |
| [`tmux-ram-revamped`](https://github.com/tmux-revamped/tmux-ram-revamped) | RAM、スワップ、メモリプレッシャーをtmuxのステータスバーに表示します。計測はバックグラウンドで行うため描画を待たせません |
| [`tmux-reorder-revamped`](https://github.com/tmux-revamped/tmux-reorder-revamped) | tmuxのステータスバー上でウィンドウのタブをマウスでドラッグして、そのウィンドウを移動します |
| [`tmux-scroll-revamped`](https://github.com/tmux-revamped/tmux-scroll-revamped) | 自分でスクロールできるアプリにはマウスホイールを渡し、それ以外ではtmuxのコピーモードに入ります |
| [`tmux-sensible-revamped`](https://github.com/tmux-revamped/tmux-sensible-revamped) | tmuxのバージョンと端末に合わせて適用され、ユーザーが設定したオプションには触れない、妥当な初期設定です |
| [`tmux-tiling-revamped`](https://github.com/tmux-revamped/tmux-tiling-revamped) | tmuxのタイル型ウィンドウ管理です。BSPのdwindleとspiralを含む8つのレイアウトと、レイアウトの取り消しがあります |
| [`tmux-time-revamped`](https://github.com/tmux-revamped/tmux-time-revamped) | ステータスバーにローカル時計と世界時計を時間帯ごとの色で表示し、カウントダウンと夏時間の警告も出します |
| [`tmux-weather-revamped`](https://github.com/tmux-revamped/tmux-weather-revamped) | wttr.inの天気をバックグラウンドで取得し、ステータスバーを待たせずに表示します |

<!-- family:end -->
