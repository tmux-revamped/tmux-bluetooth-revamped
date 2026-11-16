# tmux-bluetooth-revamped

Guidance for anyone, human or agent, changing tmux-bluetooth-revamped. What it is and how to use it lives in [README.md](README.md).

[FAMILY.md](FAMILY.md) holds everything this plugin shares with the rest of the tmux-revamped family, and it is the same in every member. This file holds only what is exclusive to tmux-bluetooth-revamped, under the same headings as the agent guide of every member. Read both before changing anything; a rule that would serve the other members goes into [`FAMILY.md`](FAMILY.md) instead of here.

## Layout

| Path | Holds |
|:-----|:------|
| [`bluetooth-revamped.tmux`](bluetooth-revamped.tmux) | The entry point TPM runs: it turns each placeholder into a `bluetooth-revamped status` call |
| [`bin/bluetooth-revamped`](bin/bluetooth-revamped) | The command: `status`, `list`, `refresh`, `doctor`, `version`, `help` and the menu. `status` and `refresh` run without loading the interface modules, so a status refresh stays cheap |
| [`lib/bluetooth.sh`](lib/bluetooth.sh) | Reading, parsing and rendering the devices, the settings and the JSON form |
| [`lib/state.sh`](lib/state.sh) | Every global this member declares: the defaults, the cache prefix and the log namespace |
| [`lib/core.sh`](lib/core.sh) | The version |
| [`lib/`](lib) | Every other file is the shared library, identical in every member |
| [`test/bin/system_profiler`](test/bin/system_profiler), [`test/bin/upower`](test/bin/upower) | The device readers every test sees, printing `REVAMPED_TEST_BLUETOOTH_DUMP` and logging each call to `REVAMPED_TEST_BLUETOOTH_LOG` |
| [`test/bluetooth.bats`](test/bluetooth.bats), [`test/commands.bats`](test/commands.bats), [`test/entrypoint.bats`](test/entrypoint.bats) | This member's suites: the library, the commands, and the entry point on a private tmux server |
| [`screens/`](screens) | The tapes and the recording's tmux config; `prepare.sh` puts a `system_profiler` with three demo devices first on `PATH` |

## Names

- Settings are the tmux options `@bluetooth_revamped_interval`, `_format`, `_separator` and `_icon`, the options `--interval`, `--format`, `--separator` and `--icon`, and the environment variables `BLUETOOTH_REVAMPED_INTERVAL`, `_FORMAT`, `_SEPARATOR` and `_ICON`.
- Placeholders are `#{bluetooth}`, `#{bluetooth_icon}`, `#{bluetooth_count}` and `#{bluetooth_min}`; `status` names them `device`, `icon`, `count` and `min`.
- The reading lives in `@bluetooth_revamped_device`, with `_ts` and `_lock`.
- The version constant is `BLUETOOTH_REVAMPED_VERSION`.

## Behaviour

- Each placeholder prints the stored reading at once. A reading older than the interval also starts one background reading, guarded by the lock option, so parallel calls start no second one.
- The entry point clears every inherited `REVAMPED_` and `BLUETOOTH_REVAMPED_` variable except the test switches and the six documented settings.
- A tmux option interval that is not a number means 30, so the status line never shows an error; the same value from `--interval` or the environment is a bad value.

## Domain rules

- macOS reads `system_profiler SPBluetoothDataType`; for AirPods it shows the lower earbud level, and the case level only when no earbud reports one.
- Linux reads `upower --dump` and keeps only devices whose native path names `bluez` or whose object path holds `_dev_`, so the laptop battery never appears.
- Any other system has no reader: the placeholders render empty and `doctor` warns.

## Release

- `BLUETOOTH_REVAMPED_VERSION` in [`lib/core.sh`](lib/core.sh) holds the version. Nobody edits it by hand.
- After a green `ci` run on `main`, [`release.yml`](.github/workflows/release.yml) runs semantic-release: a `feat` or `fix` since the last tag publishes a release, [`set-version.sh`](.github/scripts/set-version.sh) stamps the constant, and the notes go into [`CHANGELOG.md`](CHANGELOG.md).

## Gaps against FAMILY.md

As of 2026-11-16:

- The key allocation gives this member `M-h` for a detail popup, and no popup exists yet.
- No `@bluetooth_revamped_notify` for a device's low battery yet.
