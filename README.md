<div align="center">

# tmux-bluetooth-revamped

<strong>Every connected Bluetooth device and its battery in your tmux status bar, without blocking the render.</strong>

English &nbsp;|&nbsp; [日本語](README.ja.md) &nbsp;|&nbsp; [简体中文](README.zh-Hans.md) &nbsp;|&nbsp; [繁體中文（香港）](README.zh-HK.md)

[![ci](https://img.shields.io/github/actions/workflow/status/tmux-revamped/tmux-bluetooth-revamped/ci.yml?branch=main&style=flat-square&label=ci)](https://github.com/tmux-revamped/tmux-bluetooth-revamped/actions/workflows/ci.yml)
[![release](https://img.shields.io/github/v/release/tmux-revamped/tmux-bluetooth-revamped?style=flat-square&label=release)](https://github.com/tmux-revamped/tmux-bluetooth-revamped/releases/latest)
[![openssf scorecard](https://img.shields.io/ossf-scorecard/github.com/tmux-revamped/tmux-bluetooth-revamped?style=flat-square&label=openssf%20scorecard)](https://scorecard.dev/viewer/?uri=github.com/tmux-revamped/tmux-bluetooth-revamped)
[![license](https://img.shields.io/github/license/tmux-revamped/tmux-bluetooth-revamped?style=flat-square&label=license)](LICENSE)

<p align="center">
  <a href="#quick-start"><strong>Quick start</strong></a> &nbsp;|&nbsp;
  <a href="#usage">Usage</a> &nbsp;|&nbsp;
  <a href="#how-it-works">How it works</a> &nbsp;|&nbsp;
  <a href="#screens">Screens</a>
</p>

</div>

<p align="center">
  <img src="screens/hero.gif" alt="tmux with three Bluetooth devices in the status line, then bluetooth-revamped list and its menu" width="800">
</p>

```console
$ bluetooth-revamped list
AirPods Pro 85%
MX Master 3S 50%
```

The status line reads a reading stored in a tmux option, and the device query runs in the background, so a slow Bluetooth stack never stalls tmux. Nothing is written to disk.

---

## Quick start

### Prerequisites

| Tool | Version | Used for |
|:-----|:--------|:---------|
| tmux | 3.2 or later | the family floor every member supports |
| `system_profiler` | built in | the device list on macOS, Intel and Apple Silicon |
| `upower` | any | the device list on Linux, x86_64 and arm64 |
| `blueutil` | any | connect, disconnect and power on macOS, from `brew install blueutil` |
| `bluetoothctl` | any | connect, disconnect, power and the paired devices on Linux, from the `bluez` package |
| gum | optional | the menu, tables and colours of `bluetooth-revamped`; without it every command prints plain text |

### Install

Add the plugin and a placeholder to `~/.tmux.conf`, then press `prefix + I`:

```tmux
set -g @plugin 'tmux-revamped/tmux-bluetooth-revamped'
set -g status-right '#{bluetooth_icon} #{bluetooth}'
```

Without TPM, clone the repository and load the entry point after the lines that set `status-left` and `status-right`:

```bash
git clone https://github.com/tmux-revamped/tmux-bluetooth-revamped ~/.tmux/plugins/tmux-bluetooth-revamped
```

```tmux
run-shell ~/.tmux/plugins/tmux-bluetooth-revamped/bluetooth-revamped.tmux
```

`make install` in the clone also puts `bluetooth-revamped` in `~/.local/bin`, with its man page and its bash, zsh and fish completions under `~/.local/share`.

### Verify

```bash
~/.tmux/plugins/tmux-bluetooth-revamped/bin/bluetooth-revamped doctor
```

`doctor` prints one row per tool and names the device reader it found. It exits 1 only when a required tool is missing.

## Usage

| Placeholder | Output |
|:------------|:-------|
| `#{bluetooth}` | Every connected device and its battery, such as `AirPods Pro 85%, MX Master 3S 50%` |
| `#{bluetooth_icon}` | `@bluetooth_revamped_icon` while a device is connected, empty otherwise |
| `#{bluetooth_count}` | The number of connected devices, such as `2` |
| `#{bluetooth_min}` | The device with the lowest battery, such as `MX Master 3S 50%`, empty when none reports a level |

| tmux option | Default | Meaning |
|:------------|:--------|:--------|
| `@bluetooth_revamped_interval` | `30` | Seconds a reading stays fresh; a value that is not a number means `30` |
| `@bluetooth_revamped_format` | `%s` | printf format for `#{bluetooth}` |
| `@bluetooth_revamped_separator` | `, ` | Text between devices in `#{bluetooth}` |
| `@bluetooth_revamped_icon` | `BT` | Text for `#{bluetooth_icon}` |
| `@bluetooth_revamped_icons` | `0` | `1` puts a Nerd Font glyph for each device's type before it in `#{bluetooth}` |
| `@bluetooth_revamped_notify` | `0` | `1` sends a desktop notification when a connected device's battery drops below the low level |
| `@bluetooth_revamped_low` | `20` | The low battery level in percent |
| `@bluetooth_revamped_popup_key` | `M-h` | The prefix key for the device popup, or `none` |

```tmux
set -g @bluetooth_revamped_separator ' / '
set -g @bluetooth_revamped_format '[%s]'
```

| Command | What it does |
|:--------|:-------------|
| `bluetooth-revamped status NAME` | Prints one placeholder: `device`, `icon`, `count` or `min`. The placeholders call this |
| `bluetooth-revamped list` | Reads the devices now and prints one per line; `--json` prints one object |
| `bluetooth-revamped refresh` | Reads the devices now for the status line |
| `bluetooth-revamped connect DEVICE` | Connects a paired device, named by its name or address |
| `bluetooth-revamped disconnect DEVICE` | Disconnects a device |
| `bluetooth-revamped power on\|off\|toggle` | Turns Bluetooth on or off, or toggles it |
| `bluetooth-revamped popup` | The device table, then connect, disconnect or switch power; `prefix M-h` opens it |
| `bluetooth-revamped doctor` | One row per dependency, the device reader included |
| `bluetooth-revamped version` | The version, then the tmux version |
| `bluetooth-revamped help` | The help page; `man bluetooth-revamped` documents the same commands and settings |
| `bluetooth-revamped` | On a terminal, a menu: show the devices, check this machine, or read the help |

Every tmux option is also an option of the command, such as `--separator ' / '`, and an environment variable, such as `BLUETOOTH_REVAMPED_SEPARATOR`. The command line wins over the environment, and the environment over the tmux option. An empty tmux option means its default. `doctor` names any setting that holds a value the plugin does not know. `--theme NAME`, `BLUETOOTH_REVAMPED_THEME`, `BLUETOOTH_REVAMPED_ACCENT`, `KODOUGU_THEME`, `KODOUGU_ACCENT`, `NO_COLOR` and the tmux option `@revamped_theme` set the look of the command, as in every tmux-revamped tool.

```console
$ bluetooth-revamped list --json
{"devices":[{"name":"AirPods Pro","battery":85},{"name":"MX Master 3S","battery":50}]}
```

`prefix M-h` opens the device popup. `@bluetooth_revamped_popup_key` moves it to another key, and `none` binds nothing; a key you bound before the plugin loads stays yours, and `doctor` says so.

A low battery notifies once, and again only after the battery rose above the low level. Notifications are off until `@bluetooth_revamped_notify` is `1`, and the same state always shows in `#{bluetooth_min}`.

## How it works

When tmux loads the plugin, [`bluetooth-revamped.tmux`](bluetooth-revamped.tmux) turns each placeholder in `status-left` and `status-right` into a `#()` call to `bluetooth-revamped status`. The call prints the reading stored in `@bluetooth_revamped_device` at once. When that reading is older than the interval, the call also starts one background reading, guarded by a lock in `@bluetooth_revamped_device_lock` so parallel calls start no second one, and the next redraw shows the result.

Each reading also stores every paired device, with its state, address, type and battery, in `@bluetooth_revamped_details`; the popup, the actions and the icons read it.

macOS reads `system_profiler SPBluetoothDataType` and acts through `blueutil`. Linux lists paired devices with `bluetoothctl` and acts through it. AirPods report each earbud and the case, and the plugin shows the lower earbud level. Linux reads `upower --dump`, which lists only Bluetooth devices, so the laptop battery never appears.

<a id="screens"></a>

## Screens

<details>
<summary>Every screen, recorded inside a real tmux with <code>make screens</code>, with each key on the status line</summary>
<br>

<table>
<tr>
<td width="50%" valign="top"><img src="screens/status.png" alt="bluetooth-revamped: Every placeholder in the status line"><br><sub>Every placeholder in the status line, from <code>hero.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/list.png" alt="bluetooth-revamped: list"><br><sub><code>list</code>, from <code>hero.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/json.png" alt="bluetooth-revamped: list --json"><br><sub><code>list --json</code>, from <code>hero.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/menu.png" alt="bluetooth-revamped: The menu"><br><sub>The menu, from <code>hero.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/menu-list.png" alt="bluetooth-revamped: The devices from the menu"><br><sub>The devices from the menu, from <code>hero.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/status-command.png" alt="bluetooth-revamped: status count and status min"><br><sub><code>status count</code> and <code>status min</code>, from <code>stills.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/options.png" alt="bluetooth-revamped: The separator, format and icon options"><br><sub>The separator, format and icon options, from <code>stills.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/refresh.png" alt="bluetooth-revamped: refresh"><br><sub><code>refresh</code>, from <code>stills.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/doctor.png" alt="bluetooth-revamped: doctor"><br><sub><code>doctor</code>, from <code>stills.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/plain-menu.png" alt="bluetooth-revamped: The menu without gum"><br><sub>The menu without gum, from <code>stills.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/plain-doctor.png" alt="bluetooth-revamped: doctor without gum, on the tools macOS ships"><br><sub>doctor without gum, on the tools macOS ships, from <code>stills.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/version.png" alt="bluetooth-revamped: The version"><br><sub>The version, from <code>stills.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/error.png" alt="bluetooth-revamped: A bad placeholder name"><br><sub>A bad placeholder name, from <code>stills.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/accent.png" alt="bluetooth-revamped: An accent from BLUETOOTH_REVAMPED_ACCENT"><br><sub>An accent from <code>BLUETOOTH_REVAMPED_ACCENT</code>, from <code>stills.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/popup.png" alt="bluetooth-revamped: The device popup on prefix M-h"><br><sub>The device popup on <code>prefix M-h</code>, from <code>actions.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/connect.png" alt="bluetooth-revamped: A device connected from the popup"><br><sub>A device connected from the popup, from <code>actions.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/icons.png" alt="bluetooth-revamped: A glyph for each device type"><br><sub>A glyph for each device type, from <code>actions.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/power.png" alt="bluetooth-revamped: power toggle and disconnect"><br><sub><code>power toggle</code> and <code>disconnect</code>, from <code>actions.tape</code></sub></td>
</tr>
<tr>
<td width="50%" valign="top"><img src="screens/themes.png" alt="bluetooth-revamped: The header in six themes"><br><sub>The header in six themes, from <code>themes.tape</code></sub></td>
<td width="50%" valign="top"><img src="screens/help.png" alt="bluetooth-revamped: The help page"><br><sub>The help page, from <code>help.tape</code></sub></td>
</tr>
</table>

</details>

## Portability

The plugin is POSIX `sh`. CI runs every suite on each row below.

| Shell | Status |
|:------|:-------|
| `dash`, `/bin/sh` on macOS | Supported |
| `bash` 3.2 and 5.x, the system's `zsh` and Homebrew's | Supported |

| System | Status |
|:-------|:-------|
| macOS | Tahoe on Apple Silicon and Intel, with the tools it ships, Homebrew's GNU tools and Homebrew's uutils |
| Linux | Ubuntu 26.04 on x86_64 and arm64, with GNU coreutils, uutils and BusyBox |
| FreeBSD, OpenBSD, NetBSD | Not covered by CI; the placeholders stay empty and `doctor` says no reader exists |

## Development

| Command | What it runs |
|:--------|:-------------|
| `make fmt` | shfmt `-i 2` on every script |
| `make lint` | shfmt, ShellCheck, mandoc, yamllint and actionlint, at zero findings |
| `make test` | The bats suites under the system `sh` |
| `make test-all` | The suites under every installed shell, both builds of bash and zsh on macOS |
| `make test-linux` | The suites in an Ubuntu container |
| `make coverage` | bashcov on this Mac and in the Ubuntu container, merged and gated at 100 percent |
| `make screens` | The screens above, recorded from the real plugin inside tmux with VHS, on macOS |
| `make install` | The command, its man page and completions under `PREFIX` |

On macOS, `brew bundle` installs every tool these targets call, from the [`Brewfile`](Brewfile).

Commits follow the conventional commit format and go straight to `main`. After a green `ci` run on `main`, `release.yml` runs semantic-release: every `feat` or `fix` since the last tag publishes a release, stamps the version constant and adds the notes to [`CHANGELOG.md`](CHANGELOG.md).

## License

[MIT](LICENSE), copyright Gustavo Franco.

<!-- family:begin -->

## The tmux-revamped family

This plugin is one member of the tmux-revamped family. Every member carries the same contract in [`FAMILY.md`](FAMILY.md) and the same shared library, and they are built to be installed together: no member claims a key or a tmux option that another member claims.

A defect found in one member is hunted across all of them before the fix is called done.

| Member | What it does |
|---|---|
| [`tmux-autoreload-revamped`](https://github.com/tmux-revamped/tmux-autoreload-revamped) | Edit your tmux config, save, and watch it reload itself, no key, no command |
| [`tmux-battery-revamped`](https://github.com/tmux-revamped/tmux-battery-revamped) | Battery status for your tmux status bar, without ever blocking the status render |
| [`tmux-bluetooth-revamped`](https://github.com/tmux-revamped/tmux-bluetooth-revamped) | **this plugin**, Every connected Bluetooth device and its battery in your tmux status bar, without blocking the render |
| [`tmux-cpu-revamped`](https://github.com/tmux-revamped/tmux-cpu-revamped) | CPU load, temperature, and frequency in your tmux status bar, without ever blocking the render |
| [`tmux-disk-revamped`](https://github.com/tmux-revamped/tmux-disk-revamped) | Disk usage for your tmux status bar, without ever blocking the status render |
| [`tmux-extract-revamped`](https://github.com/tmux-revamped/tmux-extract-revamped) | Pick a URL, path, hash or any other token off the screen with fzf and type it at the cursor, in pure shell |
| [`tmux-fzf-revamped`](https://github.com/tmux-revamped/tmux-fzf-revamped) | Switch to, kill, rename or create tmux sessions, windows and panes from fzf pickers in a popup |
| [`tmux-git-revamped`](https://github.com/tmux-revamped/tmux-git-revamped) | Show the active pane's git branch, changes and provider counts in the tmux status bar without blocking it |
| [`tmux-gpu-revamped`](https://github.com/tmux-revamped/tmux-gpu-revamped) | GPU load, temperature, clock, power and memory in the tmux status bar, from NVIDIA, AMD, Intel and Apple GPUs |
| [`tmux-kube-revamped`](https://github.com/tmux-revamped/tmux-kube-revamped) | Current Kubernetes context and namespace in the tmux status bar, parsed from kubeconfig without kubectl |
| [`tmux-launcher-revamped`](https://github.com/tmux-revamped/tmux-launcher-revamped) | Open any terminal app in a tmux popup, window or split from one menu, starting at the project root |
| [`tmux-logging-revamped`](https://github.com/tmux-revamped/tmux-logging-revamped) | Capture any pane to a file: live logging, full scrollback, or a one-shot screenshot |
| [`tmux-music-revamped`](https://github.com/tmux-revamped/tmux-music-revamped) | Now playing in your tmux status bar, without ever blocking the status render |
| [`tmux-network-revamped`](https://github.com/tmux-revamped/tmux-network-revamped) | Network throughput in your tmux status bar, without ever blocking the render |
| [`tmux-pain-control-revamped`](https://github.com/tmux-revamped/tmux-pain-control-revamped) | Pane and window management bindings for tmux, version aware, vim friendly, every prefix key can be disabled |
| [`tmux-persist-revamped`](https://github.com/tmux-revamped/tmux-persist-revamped) | Save every tmux session, window and pane, auto-save on a timer, and restore it all after a reboot |
| [`tmux-plugin-template`](https://github.com/tmux-revamped/tmux-plugin-template) | The starting point for a tmux-revamped plugin: shared library, bats harness and CI |
| [`tmux-pomodoro-revamped`](https://github.com/tmux-revamped/tmux-pomodoro-revamped) | A Pomodoro timer in the tmux status bar that keeps all of its state in tmux options, with no temp files |
| [`tmux-ram-revamped`](https://github.com/tmux-revamped/tmux-ram-revamped) | RAM, swap and memory pressure in the tmux status bar, sampled in the background so the render never waits |
| [`tmux-reorder-revamped`](https://github.com/tmux-revamped/tmux-reorder-revamped) | Drag a window tab along the tmux status bar with the mouse to move that window |
| [`tmux-scroll-revamped`](https://github.com/tmux-revamped/tmux-scroll-revamped) | Send the mouse wheel to apps that scroll themselves and into tmux copy-mode everywhere else |
| [`tmux-sensible-revamped`](https://github.com/tmux-revamped/tmux-sensible-revamped) | Sensible tmux defaults, gated by tmux version and terminal, that leave the options you set alone |
| [`tmux-tiling-revamped`](https://github.com/tmux-revamped/tmux-tiling-revamped) | Tiling window management for tmux: eight layouts including BSP dwindle and spiral, with layout undo |
| [`tmux-time-revamped`](https://github.com/tmux-revamped/tmux-time-revamped) | Local and world clocks for the tmux status bar, colored by time of day, with countdowns and a DST warning |
| [`tmux-weather-revamped`](https://github.com/tmux-revamped/tmux-weather-revamped) | Weather for the tmux status bar from wttr.in, fetched in the background so the status line never waits |

<!-- family:end -->
