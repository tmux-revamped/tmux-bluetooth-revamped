# Changelog

# [2.1.0](https://github.com/tmux-revamped/tmux-bluetooth-revamped/compare/v2.0.0...v2.1.0) (2026-11-16)


### Bug Fixes

* bind the popup key when tmux does not know it ([cb8f9f9](https://github.com/tmux-revamped/tmux-bluetooth-revamped/commit/cb8f9f975189a6c501ca54fd9d940da5f95182f2))
* find the popup key in the whole prefix table ([c8fb5bf](https://github.com/tmux-revamped/tmux-bluetooth-revamped/commit/c8fb5bfdcefc63d456831847e5365dd23b4061a9))


### Features

* connect, disconnect and power from a popup ([c3394ce](https://github.com/tmux-revamped/tmux-bluetooth-revamped/commit/c3394ce9e18e87d381113c1396e9fb9298a15beb))

# [2.0.0](https://github.com/tmux-revamped/tmux-bluetooth-revamped/compare/v1.2.1...v2.0.0) (2026-11-16)


* feat!: rewrite the plugin in POSIX sh ([7ecd4f4](https://github.com/tmux-revamped/tmux-bluetooth-revamped/commit/7ecd4f4a9cbf788ff2246c9af621a7d40d824e11))


### Bug Fixes

* escape JSON the same way on every awk ([3e9b9b9](https://github.com/tmux-revamped/tmux-bluetooth-revamped/commit/3e9b9b9b54ab1547550eaecc2189785efab4f5de))


### Features

* add a shared desktop notifier ([2feab6d](https://github.com/tmux-revamped/tmux-bluetooth-revamped/commit/2feab6dd3e5ff41045a8ac7ff127a18ec08ca03e))
* **family:** accept bot updates in the audit ([7f3f913](https://github.com/tmux-revamped/tmux-bluetooth-revamped/commit/7f3f913ae2afdb087dc513d68d1955bea2e2859c))


### BREAKING CHANGES

* the scripts moved from src/ to bin/ and lib/, so a
status line that called src/bluetooth.sh directly instead of through a
placeholder must call bin/bluetooth-revamped status device.

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.2.1] - 2026-10-27

### Fixed

- On Linux, only Bluetooth devices are listed. The upower dump is parsed one
  `Device:` block at a time and blocks that are not bluez devices, such as the
  laptop battery and the DisplayDevice, are skipped.
- On macOS, AirPods that report `Left`, `Right` and `Case Battery Level` lines
  are listed once under their name with the lower earbud level, instead of as
  extra entries with no name. The case level is used when no earbud reports.
- On macOS, a connected device whose name starts with a symbol or a
  non-ASCII character is listed instead of skipped.
- A non-numeric `@bluetooth_revamped_interval` falls back to 30 seconds
  instead of reaching shell arithmetic, where it could break the refresh or run
  a command substitution.
- The status line jobs quote the plugin path, so the plugin works when installed
  under a directory whose name contains a space or a single quote.

## [1.2.0] - 2026-06-29

### Added

- `#{bluetooth_count}` placeholder: the number of connected devices, for narrow
  status bars.
- `#{bluetooth_min}` placeholder: a single summary of the lowest-battery device,
  for users who do not want the full list.

### Fixed

- Connected devices that report no battery level are now listed by name instead
  of being dropped. The macOS parser also skips the "Not Connected" section so
  disconnected devices never appear.

## [1.1.1] - 2026-06-23

### Changed

- Self-audit for the family hardening pass. Device detection works on both macOS
  and Linux, and the segment colors are named colors that survive the tmux 3.7
  format-expansion change. No code change needed.

## [1.1.0] - 2026-06-20

### Added

- Enumerate every connected Bluetooth device, joined by a configurable separator,
  instead of only the first device.

## [1.0.0] - 2026-06-19

### Added

- Bluetooth placeholders: `#{bluetooth}` and `#{bluetooth_icon}`.
- Non-blocking design: the device query runs in a background worker and the value
  is read from a tmux user-option, with no temp files.
- macOS via `system_profiler`, Linux via `upower`.
- Empty output when no device is connected.
