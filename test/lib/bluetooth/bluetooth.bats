#!/usr/bin/env bats

load "${BATS_TEST_DIRNAME}/../../helpers.bash"

MACOS_BT=$'Bluetooth:\n    Connected:\n        AirPods Pro:\n            Address: 00-11\n            Battery Level: 85%\n'
LINUX_BT=$'Device: /org/freedesktop/UPower/devices/headset_dev_00_11\n  native-path:          /org/bluez/hci0/dev_00_11\n  model:               WH-1000XM4\n  percentage:          80%\n'

setup() {
  setup_test_environment
  unset _BLUETOOTH_REVAMPED_BLUETOOTH_LOADED
  source "${BATS_TEST_DIRNAME}/../../../src/lib/bluetooth/bluetooth.sh"
}

teardown() {
  cleanup_test_environment
}

@test "bluetooth.sh - bt_parse_macos reads name and battery" {
  [[ "$(bt_parse_macos "${MACOS_BT}")" == "AirPods Pro 85%" ]]
}

@test "bluetooth.sh - bt_parse_macos is empty with nothing connected" {
  [[ -z "$(bt_parse_macos "Bluetooth:\n    Not Connected:")" ]]
}

@test "bluetooth.sh - bt_parse_linux reads model and percentage" {
  [[ "$(bt_parse_linux "${LINUX_BT}")" == "WH-1000XM4 80%" ]]
}

@test "bluetooth.sh - bt_parse_linux is empty without a model" {
  [[ -z "$(bt_parse_linux "percentage: 50%")" ]]
}

@test "bluetooth.sh - bt_parse_macos enumerates every connected device" {
  local txt=$'Bluetooth:\n    Connected:\n        AirPods Pro:\n            Battery Level: 85%\n        Magic Mouse:\n            Battery Level: 50%\n'
  run bt_parse_macos "${txt}"
  [[ "${lines[0]}" == "AirPods Pro 85%" ]]
  [[ "${lines[1]}" == "Magic Mouse 50%" ]]
}

@test "bluetooth.sh - bt_parse_linux enumerates every device" {
  local txt=$'Device: /org/freedesktop/UPower/devices/headset_dev_00_11\n  native-path: /org/bluez/hci0/dev_00_11\n  model: WH-1000XM4\n  percentage: 80%\nDevice: /org/freedesktop/UPower/devices/mouse_dev_00_22\n  native-path: /org/bluez/hci0/dev_00_22\n  model: MX Master\n  percentage: 40%\n'
  run bt_parse_linux "${txt}"
  [[ "${lines[0]}" == "WH-1000XM4 80%" ]] || false
  [[ "${lines[1]}" == "MX Master 40%" ]]
}

@test "bluetooth.sh - read_bluetooth uses system_profiler on macOS" {
  _PLATFORM_OS_CACHE="Darwin"
  _read_bt_macos() { printf '%s' "${MACOS_BT}"; }
  [[ "$(read_bluetooth)" == "AirPods Pro 85%" ]]
}

@test "bluetooth.sh - read_bluetooth uses upower on Linux" {
  _PLATFORM_OS_CACHE="Linux"
  has_command() { return 0; }
  _read_bt_linux() { printf '%s' "${LINUX_BT}"; }
  [[ "$(read_bluetooth)" == "WH-1000XM4 80%" ]]
}

@test "bluetooth.sh - read_bluetooth is empty without upower on Linux" {
  _PLATFORM_OS_CACHE="Linux"
  has_command() { return 1; }
  [[ -z "$(read_bluetooth)" ]]
}

@test "bluetooth.sh - bt_parse_macos lists a connected device with no battery" {
  local txt=$'Bluetooth:\n    Connected:\n        Magic Keyboard:\n            Address: 00-22\n'
  [[ "$(bt_parse_macos "${txt}")" == "Magic Keyboard" ]]
}

@test "bluetooth.sh - bt_parse_macos mixes battery and no-battery devices" {
  local txt=$'Bluetooth:\n    Connected:\n        AirPods Pro:\n            Battery Level: 85%\n        Magic Keyboard:\n            Address: 00-22\n'
  run bt_parse_macos "${txt}"
  [[ "${lines[0]}" == "AirPods Pro 85%" ]]
  [[ "${lines[1]}" == "Magic Keyboard" ]]
}

@test "bluetooth.sh - bt_parse_macos skips the Not Connected section" {
  local txt=$'Bluetooth:\n    Connected:\n        AirPods Pro:\n            Battery Level: 85%\n    Not Connected:\n        Old Mouse:\n            Address: 00-99\n'
  run bt_parse_macos "${txt}"
  [[ "${#lines[@]}" -eq 1 ]]
  [[ "${lines[0]}" == "AirPods Pro 85%" ]]
}

@test "bluetooth.sh - bt_parse_linux lists a device with no percentage" {
  local txt=$'Device: /org/freedesktop/UPower/devices/keyboard_dev_00_33\n  native-path:          /org/bluez/hci0/dev_00_33\n  model:               Keychron K2\n'
  [[ "$(bt_parse_linux "${txt}")" == "Keychron K2" ]]
}

@test "bluetooth.sh - bt_parse_linux mixes battery and no-battery devices" {
  local txt=$'Device: /org/freedesktop/UPower/devices/headset_dev_00_11\n  native-path: /org/bluez/hci0/dev_00_11\n  model: WH-1000XM4\n  percentage: 80%\nDevice: /org/freedesktop/UPower/devices/keyboard_dev_00_33\n  native-path: /org/bluez/hci0/dev_00_33\n  model: Keychron K2\n'
  run bt_parse_linux "${txt}"
  [[ "${lines[0]}" == "WH-1000XM4 80%" ]] || false
  [[ "${lines[1]}" == "Keychron K2" ]]
}

@test "bluetooth.sh - bt_parse_linux keeps only bluez devices" {
  # Arrange
  local txt=$'Device: /org/freedesktop/UPower/devices/battery_BAT0\n  native-path:          BAT0\n  model:               5B10W13930\n  percentage:          64%\nDevice: /org/freedesktop/UPower/devices/headset_dev_00_11\n  native-path:          /org/bluez/hci0/dev_00_11\n  model:               WH-1000XM4\n  percentage:          80%\nDevice: /org/freedesktop/UPower/devices/DisplayDevice\n  model:               Display\n  percentage:          64%\nDaemon:\n  daemon-version:  1.90.2\n'

  # Act
  run bt_parse_linux "${txt}"

  # Assert
  [ "${output}" = "WH-1000XM4 80%" ]
}

@test "bluetooth.sh - bt_parse_macos folds AirPods earbud and case levels into one device" {
  # Arrange
  local txt=$'Bluetooth:\n    Connected:\n        AirPods Pro:\n            Address: 00-11\n            Case Battery Level: 100%\n            Left Battery Level: 90%\n            Right Battery Level: 85%\n        Magic Mouse:\n            Battery Level: 50%\n'

  # Act
  run bt_parse_macos "${txt}"

  # Assert
  [ "${#lines[@]}" -eq 2 ]
  [ "${lines[0]}" = "AirPods Pro 85%" ]
  [ "${lines[1]}" = "Magic Mouse 50%" ]
}

@test "bluetooth.sh - bt_parse_macos falls back to the case level when only the case reports" {
  # Arrange
  local txt=$'Bluetooth:\n    Connected:\n        AirPods:\n            Case Battery Level: 70%\n'

  # Act
  run bt_parse_macos "${txt}"

  # Assert
  [ "${output}" = "AirPods 70%" ]
}

@test "bluetooth.sh - bt_parse_macos lists a device whose name starts with a symbol" {
  # Arrange
  local txt=$'Bluetooth:\n    Connected:\n        (Work) Headset:\n            Battery Level: 60%\n        _Mouse:\n            Address: 00-44\n'

  # Act
  run bt_parse_macos "${txt}"

  # Assert
  [ "${#lines[@]}" -eq 2 ]
  [ "${lines[0]}" = "(Work) Headset 60%" ]
  [ "${lines[1]}" = "_Mouse" ]
}
