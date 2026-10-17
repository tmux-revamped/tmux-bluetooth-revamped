<div align="center">

# tmux-bluetooth-revamped

<strong>接続中のすべてのBluetooth機器とその電池残量をtmuxのステータスバーに表示し、描画を止めません。</strong>

[English](README.md) &nbsp;|&nbsp; 日本語 &nbsp;|&nbsp; [简体中文](README.zh-Hans.md) &nbsp;|&nbsp; [繁體中文（香港）](README.zh-HK.md)

[![Tests](https://github.com/tmux-revamped/tmux-bluetooth-revamped/actions/workflows/tests.yml/badge.svg)](https://github.com/tmux-revamped/tmux-bluetooth-revamped/actions/workflows/tests.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-1.2.0-blue.svg)](CHANGELOG.md)

<p align="center">
  <a href="#what-it-does">機能</a> &nbsp;|&nbsp;
  <a href="#requirements">動作要件</a> &nbsp;|&nbsp;
  <a href="#installation">インストール</a> &nbsp;|&nbsp;
  <a href="#usage">使い方</a> &nbsp;|&nbsp;
  <a href="#configuration">設定</a> &nbsp;|&nbsp;
  <a href="#key-bindings">キーバインド</a> &nbsp;|&nbsp;
  <a href="#how-it-works">仕組み</a>
</p>

</div>

プレースホルダー**4**個。オプション**4**個。機器の問い合わせは既定で**30**秒に1回。CIはLinuxとmacOSの**10**通りのツールチェーンの組み合わせでテストを実行します。

---

<a id="what-it-does"></a>

## 機能

`status-left`と`status-right`の`#{bluetooth*}`プレースホルダーを、接続中のBluetooth機器とその電池残量に置き換えます。例：`AirPods 85%, MX Master 50%`。ステータスラインはtmuxのオプションにキャッシュされた値を読み、機器の問い合わせはバックグラウンドで行います。ディスクには何も書き込みません。

- 電池残量を報告しない機器は名前だけを表示します。
- 左右とケースの残量を報告するAirPodsは1つにまとめ、イヤホンの低い方の残量を表示します。
- LinuxではBluetooth機器だけを表示するため、ノートパソコンの電池は表示されません。
- 機器が接続されていないとき、機器の一覧とアイコンは空になり、台数は`0`になります。

<a id="requirements"></a>

## 動作要件

| ツール | バージョン | 用途 |
|:-----|:--------|:-----------|
| tmux | 3.2以降 | ファミリー共通の最低バージョン |
| bash | 3.2以降 | macOSの`/bin/bash`を含むすべてのスクリプト |
| `upower` | 任意 | Linuxのみ。機器の一覧 |

| プラットフォーム | 情報源 |
|:---------|:-------|
| macOS、IntelとApple Silicon | 標準搭載の`system_profiler SPBluetoothDataType` |
| Linux、x86_64とarm64 | `upower --dump` |

<a id="installation"></a>

## インストール

### TPMでインストール

`~/.tmux.conf`にプラグインとプレースホルダーを追加し、`prefix + I`を押します。

```tmux
set -g @plugin 'tmux-revamped/tmux-bluetooth-revamped'
set -g status-right '#{bluetooth_icon} #{bluetooth}'
```

### 手動インストール

```bash
git clone https://github.com/tmux-revamped/tmux-bluetooth-revamped ~/.tmux/plugins/tmux-bluetooth-revamped
```

次の行を`~/.tmux.conf`の`status-left`と`status-right`を設定する行より後に追加し、tmuxを再読み込みします。

```tmux
run-shell ~/.tmux/plugins/tmux-bluetooth-revamped/bluetooth-revamped.tmux
```

<a id="usage"></a>

## 使い方

`status-left`か`status-right`にプレースホルダーを書きます。プラグインは読み込み時にそれを置き換えます。完全な例は[`examples/status-right.tmux.conf`](examples/status-right.tmux.conf)にあります。

| プレースホルダー | 出力 |
|:------------|:-------|
| `#{bluetooth}` | 接続中のすべての機器とその電池残量。例：`AirPods 85%, MX Master 50%` |
| `#{bluetooth_icon}` | 機器が接続されている間は`@bluetooth_revamped_icon`、それ以外は空 |
| `#{bluetooth_count}` | 接続中の機器の台数。例：`2` |
| `#{bluetooth_min}` | 電池残量が最も少ない機器。例：`MX Master 50%`。残量を報告する機器がなければ空 |

<a id="configuration"></a>

## 設定

| オプション | 既定値 | 意味 |
|:-------|:--------|:--------|
| `@bluetooth_revamped_interval` | `30` | 機器の読み取りを新しいとみなす秒数。数値でない値は`30`になります |
| `@bluetooth_revamped_format` | `%s` | `#{bluetooth}`のprintf書式 |
| `@bluetooth_revamped_separator` | `, ` | `#{bluetooth}`の機器の間の文字列 |
| `@bluetooth_revamped_icon` | `BT` | `#{bluetooth_icon}`の文字列 |

```tmux
set -g @bluetooth_revamped_separator ' | '
set -g @bluetooth_revamped_format '[%s]'
```

### 内部状態

次のオプションはプラグインが自身で書き込みます。設定しないでください。

| オプション | 内容 |
|:-------|:------|
| `@bluetooth_revamped_device` | キャッシュされた機器の一覧。1行に1台 |
| `@bluetooth_revamped_device_ts`、`@bluetooth_revamped_device_lock` | 一覧を読んだ時刻と、更新中かどうか |

<a id="key-bindings"></a>

## キーバインド

このプラグインはキーを割り当てません。

<a id="how-it-works"></a>

## 仕組み

各プレースホルダーは[`src/bluetooth.sh`](src/bluetooth.sh)を呼ぶ`#()`になります。呼び出しはキャッシュされた機器の一覧をすぐに出力します。一覧が`@bluetooth_revamped_interval`秒より古ければ、バックグラウンドでの更新を1つ開始します。更新はロックで守られ、並行した呼び出しが2つ目を開始することはありません。次にステータスが描き直されると新しい一覧が表示されます。

<a id="development"></a>

## 開発

| コマンド | 実行内容 |
|:--------|:-------------|
| `make test` | [`test/`](test)以下のbatsテスト |
| `make lint` | すべてのシェルファイルへのshellcheck |
| `make coverage` | Linuxでのkcovによる行カバレッジ。95%未満で失敗します |

<a id="license"></a>

## ライセンス

[MIT](LICENSE)、copyright Gustavo Franco。

<!-- family:begin -->

## tmux-revampedファミリー

このプラグインはtmux-revampedファミリーの一員です。すべてのメンバーが[`FAMILY.md`](FAMILY.md)の同じ規約、`family/`以下の同じツール、同じ共有ライブラリを持ち、チェックサムの一覧でバイト単位まで同一に保たれています。一緒にインストールする前提で作られており、どのメンバーも他のメンバーが使うキーやtmuxオプションを使いません。

あるメンバーで見つかった不具合は、修正の完了を宣言する前にすべてのメンバーで探します。この義務は記憶に頼らず規約に書かれており、`family/bin/sweep`で果たします。

| メンバー | 内容 |
|---|---|
| [`tmux-autoreload-revamped`](https://github.com/tmux-revamped/tmux-autoreload-revamped) | tmuxの設定を編集して保存するだけで、キーもコマンドも使わずに自動で再読み込みされる |
| [`tmux-battery-revamped`](https://github.com/tmux-revamped/tmux-battery-revamped) | tmuxのステータスバーに電池の状態を表示し、描画を一切止めない |
| [`tmux-bluetooth-revamped`](https://github.com/tmux-revamped/tmux-bluetooth-revamped) | **このプラグイン**、接続中のすべてのBluetooth機器とその電池残量をtmuxのステータスバーに表示し、描画を止めない |
| [`tmux-cpu-revamped`](https://github.com/tmux-revamped/tmux-cpu-revamped) | CPUの負荷、温度、周波数をtmuxのステータスバーに表示し、描画を一切止めない |
| [`tmux-disk-revamped`](https://github.com/tmux-revamped/tmux-disk-revamped) | tmuxのステータスバーにディスク使用量を表示し、描画を一切止めない |
| [`tmux-extract-revamped`](https://github.com/tmux-revamped/tmux-extract-revamped) | 画面上のURL、パス、ハッシュなどの文字列をfzfで選び、カーソル位置に入力する。純粋なシェルで実装 |
| [`tmux-fzf-revamped`](https://github.com/tmux-revamped/tmux-fzf-revamped) | ポップアップのfzf選択画面からtmuxのセッション、ウィンドウ、ペインを切り替え、終了、改名、作成する |
| [`tmux-git-revamped`](https://github.com/tmux-revamped/tmux-git-revamped) | アクティブなペインのgitブランチ、変更、プロバイダーの件数をtmuxのステータスバーに表示し、描画を止めない |
| [`tmux-gpu-revamped`](https://github.com/tmux-revamped/tmux-gpu-revamped) | NVIDIA、AMD、Intel、AppleのGPUの負荷、温度、クロック、電力、メモリをtmuxのステータスバーに表示する |
| [`tmux-kube-revamped`](https://github.com/tmux-revamped/tmux-kube-revamped) | 現在のKubernetesコンテキストと名前空間をkubectlなしでkubeconfigから読み取り、tmuxのステータスバーに表示する |
| [`tmux-launcher-revamped`](https://github.com/tmux-revamped/tmux-launcher-revamped) | 任意のTUIアプリを現在のペインのディレクトリでポップアップかウィンドウに起動する。キーは設定可能 |
| [`tmux-logging-revamped`](https://github.com/tmux-revamped/tmux-logging-revamped) | 任意のペインをファイルに保存する。ライブのログ記録、スクロールバック全体、1回限りのスクリーンショット |
| [`tmux-music-revamped`](https://github.com/tmux-revamped/tmux-music-revamped) | 再生中の曲をtmuxのステータスバーに表示し、描画を一切止めない |
| [`tmux-network-revamped`](https://github.com/tmux-revamped/tmux-network-revamped) | ネットワークのスループットをtmuxのステータスバーに表示し、描画を一切止めない |
| [`tmux-pain-control-revamped`](https://github.com/tmux-revamped/tmux-pain-control-revamped) | tmuxの標準的なペインとウィンドウの操作キー。バージョンに対応し、vim風で、すべて設定可能 |
| [`tmux-persist-revamped`](https://github.com/tmux-revamped/tmux-persist-revamped) | tmuxのすべてのセッション、ウィンドウ、ペインを保存し、定期的に自動保存し、再起動後にすべて復元する |
| [`tmux-plugin-template`](https://github.com/tmux-revamped/tmux-plugin-template) | tmux-revampedプラグインの出発点。共有ライブラリ、batsのテスト環境、CI、ファミリーのツール |
| [`tmux-pomodoro-revamped`](https://github.com/tmux-revamped/tmux-pomodoro-revamped) | tmuxのステータスバーに表示するポモドーロタイマー。状態はすべてtmuxのオプションに持ち、一時ファイルを使わない |
| [`tmux-ram-revamped`](https://github.com/tmux-revamped/tmux-ram-revamped) | RAM、スワップ、メモリ圧迫をtmuxのステータスバーに表示する。計測はバックグラウンドで行い、描画を待たせない |
| [`tmux-reorder-revamped`](https://github.com/tmux-revamped/tmux-reorder-revamped) | tmuxのステータスバー上のウィンドウのタブをマウスでドラッグして、そのウィンドウを移動する |
| [`tmux-scroll-revamped`](https://github.com/tmux-revamped/tmux-scroll-revamped) | マウスホイールを、自分でスクロールするアプリにはそのまま送り、それ以外ではtmuxのコピーモードに入れる |
| [`tmux-sensible-revamped`](https://github.com/tmux-revamped/tmux-sensible-revamped) | tmuxのバージョンと端末に応じて適用する実用的な既定値。自分で設定したオプションには触れない |
| [`tmux-tiling-revamped`](https://github.com/tmux-revamped/tmux-tiling-revamped) | tmuxのタイル型ウィンドウ管理。BSPのdwindleとspiralを含む8種類のレイアウトと、レイアウトの取り消し |
| [`tmux-time-revamped`](https://github.com/tmux-revamped/tmux-time-revamped) | tmuxのステータスバーに現地時計と世界時計を表示する。時間帯で色分けし、カウントダウンと夏時間の警告付き |
| [`tmux-weather-revamped`](https://github.com/tmux-revamped/tmux-weather-revamped) | wttr.inの天気をtmuxのステータスバーに表示する。取得はバックグラウンドで行い、ステータスラインを待たせない |

### インストールの確認

すべてのメンバーがディスク上にあれば、1つのコマンドでメンバー間の衝突を報告します。

```sh
family/bin/doctor --live
```

各メンバーと動作中のtmuxサーバーを読み、重複したキー、重複したステータスのプレースホルダー、命名規則に外れたオプション、規約のバージョンが遅れているメンバーを報告します。

<!-- family:end -->
