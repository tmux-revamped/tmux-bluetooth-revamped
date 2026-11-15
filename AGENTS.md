# tmux-bluetooth-revamped

Guidance for anyone, human or agent, changing tmux-bluetooth-revamped. What it is and how to use it lives in [README.md](README.md).

[FAMILY.md](FAMILY.md) holds everything this plugin shares with the rest of the tmux-revamped family, and it is the same in every member. This file holds only what is exclusive to tmux-bluetooth-revamped, under the same headings as the agent guide of every member. Read both before changing anything; a rule that would serve the other members goes into [`FAMILY.md`](FAMILY.md) instead of here.

## Layout

| Path | Holds |
|:-----|:------|
| [`bluetooth-revamped.tmux`](bluetooth-revamped.tmux) | The entry point TPM runs |
| [`src/bluetooth.sh`](src/bluetooth.sh) | The script the placeholders, keys and popups call |
| [`src/lib/bluetooth/`](src/lib/bluetooth) | This member's modules |
| [`src/lib/utils/constants.sh`](src/lib/utils/constants.sh) | This member's constants, including its version |
| [`src/lib/utils/`](src/lib/utils), [`src/lib/tmux/`](src/lib/tmux) | The shared library. Every file there except `constants.sh` is owned by the family |
| [`test/`](test) | The bats suite. `helpers.bash` and `tmux_helpers.bash` are owned; this member's own mocks go in the `_local` files |
| [`family/`](family) | The family tooling, owned |

## Names

- Settings are tmux options named `@bluetooth_revamped_<setting>`.
- Placeholders include `#{bluetooth_count}`, `#{bluetooth_icon}`.
- The version constant is `BLUETOOTH_REVAMPED_VERSION`.
- Its command-line tool, once it exists, is `bluetooth-revamped`.

## Behaviour

- Shows every connected Bluetooth device and its battery in the status line, without blocking the render.
- `M-h` opens the detail popup.
- Each placeholder becomes a `#()` call that prints the cached device list at once. A list older than `@bluetooth_revamped_interval` seconds also starts one background refresh, guarded by a lock so parallel calls start no second one.

## Domain rules

- macOS reads `system_profiler SPBluetoothDataType`; Linux reads `upower --dump`, which lists only Bluetooth devices, so the laptop battery never appears.

## Release

- `BLUETOOTH_REVAMPED_VERSION` in [`src/lib/utils/constants.sh`](src/lib/utils/constants.sh) holds the version. It must equal the newest versioned heading in [`CHANGELOG.md`](CHANGELOG.md) and the README's version badge, which the `version` job in `tests.yml` checks.
- A push to `main` whose version has no tag yet makes the `release` job in `tests.yml` tag `vX.Y.Z` and publish a GitHub release with that changelog section.
- Unreleased changes sit under `## [Unreleased]` in [`CHANGELOG.md`](CHANGELOG.md) until a release is cut.

## Gaps against FAMILY.md

As of 2026-11-15:

- Every script is bash, under `#!/usr/bin/env bash`, not POSIX `sh`, so it is untested under `dash`, `zsh` and BusyBox `sh`.
- The code lives in [`src/`](src) and [`src/lib/`](src/lib); there is no `bin/bluetooth-revamped`, `lib/state.sh` or `lib/core.sh`.
- No `bluetooth-revamped` command with `help`, `version` and `doctor` in the family's form, no man page, no completions and no `manifest.json`.
- No gum interface: no `lib/ui.sh`, `lib/table.awk`, themes or `test/bin/gum`.
- No `screens/` and no recordings in the README.
- The README sections are not the family's order of Quick start, Usage, topic sections, Portability, Development and License.
- Coverage is kcov with a 95 percent floor on Linux, not bashcov at 100 percent merged from macOS and Linux.
- CI tests GNU, BSD and uutils tools in `tests.yml`, but not the six toolsets through `.github/scripts/toolset.sh`, and no shell matrix under `sh`, `dash`, `bash` and `zsh`.
- No golden transcripts, `call.sh`, `run-matrix.sh` or `linux-container.sh`.
- The version is written by hand and released by `tests.yml`; there is no semantic-release, `package.json`, `release.yml` with `recover`, `bot-merge.yml` or Renovate.
- CI is `tests.yml`, `family.yml` and `security.yml`, not `ci.yml`, and no job starts with `step-security/harden-runner`.
- No `.editorconfig`, `.yamllint.yml`, `scripts/check-names.sh` or shfmt; the Makefile has `help`, `test`, `test-unit`, `coverage`, `lint` and `clean`, not the family's targets.
- No `@bluetooth_revamped_notify` for a device's low battery yet.
