# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Fixed

- On Linux, only Bluetooth devices are listed. The upower dump is parsed one
  `Device:` block at a time and blocks that are not bluez devices, such as the
  laptop battery and the DisplayDevice, are skipped.
- On macOS, AirPods that report `Left`, `Right` and `Case Battery Level` lines
  are listed once under their name with the lower earbud level, instead of as
  extra entries with no name. The case level is used when no earbud reports.
- On macOS, a connected device whose name starts with a symbol or a
  non-ASCII character is listed instead of skipped.

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
