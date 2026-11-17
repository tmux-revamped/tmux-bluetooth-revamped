# tmux-bluetooth-revamped

Guidance for anyone, human or agent, changing tmux-bluetooth-revamped. What it is and how to use it lives in [README.md](README.md).

[FAMILY.md](FAMILY.md) holds everything this plugin shares with the rest of the tmux-revamped family, and it is the same in every member. This file holds only what is exclusive to tmux-bluetooth-revamped, under the same headings as the agent guide of every member. Read both before changing anything; a rule that would serve the other members goes into [`FAMILY.md`](FAMILY.md) instead of here.

## Layout

| Path | Holds |
|:-----|:------|
| [`bluetooth-revamped.tmux`](bluetooth-revamped.tmux) | The entry point TPM runs: it turns each placeholder into a `bluetooth-revamped status` call and binds the popup key |
| [`bin/bluetooth-revamped`](bin/bluetooth-revamped) | The command: `status`, `list`, `refresh`, `connect`, `disconnect`, `power`, `popup`, `doctor`, `version`, `help` and the menu. `status` and `refresh` run without loading the interface modules, so a status refresh stays cheap |
| [`lib/bluetooth.sh`](lib/bluetooth.sh) | Reading, parsing and rendering the devices, the device records, the icons, the low battery alert, the settings and the JSON form |
| [`lib/actions.sh`](lib/actions.sh) | Connect, disconnect and power through `blueutil` or `bluetoothctl`, reporting through `BLUETOOTH_REVAMPED_PROBLEM` and `BLUETOOTH_REVAMPED_DONE` |
| [`lib/state.sh`](lib/state.sh) | Every global this member declares: the defaults, the cache prefix and the log namespace |
| [`lib/core.sh`](lib/core.sh) | The version |
| [`lib/`](lib) | Every other file is the shared library, identical in every member |
| [`test/bin/system_profiler`](test/bin/system_profiler), [`test/bin/upower`](test/bin/upower), [`test/bin/blueutil`](test/bin/blueutil), [`test/bin/bluetoothctl`](test/bin/bluetoothctl) | The tools every test sees: the readers print `REVAMPED_TEST_BLUETOOTH_DUMP`, `bluetoothctl` prints `REVAMPED_TEST_BLUETOOTH_PAIRED` and `_CONNECTED`, the power state follows `REVAMPED_TEST_BLUETOOTH_POWER`, a failure follows `REVAMPED_TEST_BLUETOOTH_FAIL`, and each call is logged to `REVAMPED_TEST_BLUETOOTH_LOG` |
| [`test/bluetooth.bats`](test/bluetooth.bats), [`test/bluetooth-records.bats`](test/bluetooth-records.bats), [`test/actions.bats`](test/actions.bats), [`test/commands.bats`](test/commands.bats), [`test/commands-actions.bats`](test/commands-actions.bats), [`test/entrypoint.bats`](test/entrypoint.bats) | This member's suites: the library, the actions, the commands, and the entry point on a private tmux server |
| [`screens/`](screens) | The tapes and the recording's tmux config; `prepare.sh` puts a `system_profiler` and a `blueutil` first on `PATH` that read and change a table of three demo devices. VHS cannot send Alt, so a tape presses `Escape` then the letter, which tmux reads as one `M-` key within the recording's `escape-time` |

## Names

- Settings are the tmux options `@bluetooth_revamped_interval`, `_format`, `_separator`, `_icon`, `_icons`, `_notify`, `_low` and `_popup_key`, the options of the same names with dashes, such as `--popup-key`, and the environment variables `BLUETOOTH_REVAMPED_INTERVAL` through `_POPUP_KEY`.
- Placeholders are `#{bluetooth}`, `#{bluetooth_icon}`, `#{bluetooth_count}` and `#{bluetooth_min}`; `status` names them `device`, `icon`, `count` and `min`.
- The reading lives in `@bluetooth_revamped_device`, with `_ts` and `_lock`; every paired device's record in `@bluetooth_revamped_details`, one tab-separated line of state, address, type, battery and name; the devices already notified in `@bluetooth_revamped_notified`.
- The version constant is `BLUETOOTH_REVAMPED_VERSION`.

## Behaviour

- Each placeholder prints the stored reading at once. A reading older than the interval also starts one background reading, guarded by the lock option, so parallel calls start no second one.
- The entry point clears every inherited `REVAMPED_` and `BLUETOOTH_REVAMPED_` variable except the test switches and the ten documented settings.
- `prefix M-h` opens `bluetooth-revamped popup` in a `display-popup`; a key the person bound first stays theirs, and `doctor` reports it. The popup's command writes each `#` of the checkout path as `"$(printf '%b' '\0043')"`, while the status calls double it, since tmux expands formats in a status line and not in a popup's command.
- A low battery notifies once while it stays below `@bluetooth_revamped_low`, only when `@bluetooth_revamped_notify` is `1`.
- `status` and `refresh` load no interface module, and `#{bluetooth}` reads its separator, format, icons switch and records in one `tmux display-message` call; an empty tmux option there means the default.
- A tmux option interval that is not a number means 30, so the status line never shows an error; the same value from `--interval` or the environment is a bad value.

## Domain rules

- tmux expands formats in the output of a status job, so each device name has every `#` doubled as `#{bluetooth}` prints it. The stored list, `list` and the popup keep the name as the system gives it.
- macOS reads `system_profiler SPBluetoothDataType`; for AirPods it shows the lower earbud level, and the case level only when no earbud reports one.
- Linux reads `upower --dump` and keeps only devices whose native path names `bluez` or whose object path holds `_dev_`, so the laptop battery never appears.
- Any other system has no reader: the placeholders render empty and `doctor` warns.

## Release

- `BLUETOOTH_REVAMPED_VERSION` in [`lib/core.sh`](lib/core.sh) holds the version. Nobody edits it by hand.
- After a green `ci` run on `main`, [`release.yml`](.github/workflows/release.yml) runs semantic-release: a `feat` or `fix` since the last tag publishes a release, [`set-version.sh`](.github/scripts/set-version.sh) stamps the constant, and the notes go into [`CHANGELOG.md`](CHANGELOG.md).

## Gaps against FAMILY.md

As of 2026-11-16, none.
