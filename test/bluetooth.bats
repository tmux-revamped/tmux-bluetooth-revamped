#!/usr/bin/env bats
# shellcheck disable=SC2016,SC2030,SC2031,SC2034

# shellcheck source=test/bluetooth_helpers.bash
source "${BATS_TEST_DIRNAME:-.}/bluetooth_helpers.bash"

@test "bluetooth - macOS reads a device's name and battery" {
  # Arrange
  local text='Bluetooth:\n    Connected:\n        AirPods Pro:\n            Address: 00-11\n            Battery Level: 85%\n'

  # Act
  parse macos "${text}"

  # Assert
  [[ "${output}" == "AirPods Pro 85%" ]]
}

@test "bluetooth - macOS lists nothing when nothing is connected" {
  # Arrange
  local text='Bluetooth:\n    Not Connected:\n        Old Mouse:\n            Address: 00-99\n'

  # Act
  parse macos "${text}"

  # Assert
  [[ -z "${output}" ]]
}

@test "bluetooth - macOS lists every connected device, with or without a battery" {
  # Arrange
  local text='Bluetooth:\n    Connected:\n        AirPods Pro:\n            Battery Level: 85%\n        Magic Keyboard:\n            Address: 00-22\n        Magic Mouse:\n            Battery Level: 50%\n    Not Connected:\n        Old Mouse:\n            Address: 00-99\n'

  # Act
  parse macos "${text}"

  # Assert
  [[ "${#lines[@]}" -eq 3 ]]
  [[ "${lines[0]}" == "AirPods Pro 85%" ]]
  [[ "${lines[1]}" == "Magic Keyboard" ]]
  [[ "${lines[2]}" == "Magic Mouse 50%" ]]
}

@test "bluetooth - macOS folds earbud levels into the lower one" {
  # Arrange
  local text='Bluetooth:\n    Connected:\n        AirPods Pro:\n            Case Battery Level: 100%\n            Left Battery Level: 90%\n            Right Battery Level: 85%\n'

  # Act
  parse macos "${text}"

  # Assert
  [[ "${output}" == "AirPods Pro 85%" ]]
}

@test "bluetooth - macOS uses the case level when it is the only one" {
  # Arrange
  local text='Bluetooth:\n    Connected:\n        AirPods Pro:\n            Case Battery Level: 40%\n'

  # Act
  parse macos "${text}"

  # Assert
  [[ "${output}" == "AirPods Pro 40%" ]]
}

@test "bluetooth - Linux reads a Bluetooth device's model and percentage" {
  # Arrange
  local text='Device: /org/freedesktop/UPower/devices/headset_dev_00_11\n  native-path:          /org/bluez/hci0/dev_00_11\n  model:               WH-1000XM4\n  percentage:          80%\n'

  # Act
  parse linux "${text}"

  # Assert
  [[ "${output}" == "WH-1000XM4 80%" ]]
}

@test "bluetooth - Linux lists every Bluetooth device and leaves out the laptop battery" {
  # Arrange
  local text='Device: /org/freedesktop/UPower/devices/battery_BAT0\n  native-path:          BAT0\n  model:               5B10W13930\n  percentage:          64%\nDevice: /org/freedesktop/UPower/devices/headset_dev_00_11\n  native-path: /org/bluez/hci0/dev_00_11\n  model: WH-1000XM4\n  percentage: 80%\nDevice: /org/freedesktop/UPower/devices/keyboard_dev_00_33\n  model: Keychron K2\nDaemon:\n  daemon-version:  1.90.2\n'

  # Act
  parse linux "${text}"

  # Assert
  [[ "${#lines[@]}" -eq 2 ]]
  [[ "${lines[0]}" == "WH-1000XM4 80%" ]]
  [[ "${lines[1]}" == "Keychron K2" ]]
}

@test "bluetooth - Linux lists nothing without a model" {
  # Arrange
  local text='Device: /org/freedesktop/UPower/devices/headset_dev_00_11\n  percentage: 50%\n'

  # Act
  parse linux "${text}"

  # Assert
  [[ -z "${output}" ]]
}

@test "bluetooth - read asks system_profiler on macOS" {
  # Arrange
  export REVAMPED_TEST_UNAME_S=Darwin
  dump 'Bluetooth:\n    Connected:\n        MX Master:\n            Battery Level: 50%\n'

  # Act
  lib_run bluetooth bluetooth_revamped_read

  # Assert
  [[ "${output}" == "MX Master 50%" ]]
  grep -q 'system_profiler SPBluetoothDataType$' "${REVAMPED_TEST_BLUETOOTH_LOG}"
}

@test "bluetooth - read asks upower on Linux" {
  # Arrange
  export REVAMPED_TEST_UNAME_S=Linux
  dump 'Device: /org/freedesktop/UPower/devices/mouse_dev_00_22\n  model: MX Master\n  percentage: 40%\n'

  # Act
  lib_run bluetooth bluetooth_revamped_read

  # Assert
  [[ "${output}" == "MX Master 40%" ]]
  grep -q 'upower --dump$' "${REVAMPED_TEST_BLUETOOTH_LOG}"
}

@test "bluetooth - read is empty on Linux without upower" {
  # Arrange
  export REVAMPED_TEST_UNAME_S=Linux
  harness_hide upower

  # Act
  lib_run bluetooth bluetooth_revamped_read

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ -z "${output}" ]]
}

@test "bluetooth - read is empty on a system with no reader" {
  # Arrange
  export REVAMPED_TEST_UNAME_S=FreeBSD

  # Act
  lib_run bluetooth bluetooth_revamped_read

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ -z "${output}" ]]
  [[ ! -e "${REVAMPED_TEST_BLUETOOTH_LOG}" ]]
}

@test "bluetooth - a setting from the environment wins over the tmux option" {
  # Arrange
  option @bluetooth_revamped_icon tmux
  export BLUETOOTH_REVAMPED_ICON=env

  # Act
  lib_call bluetooth bluetooth_revamped_setting icon BT

  # Assert
  [[ "${output}" == "env" ]]
}

@test "bluetooth - an empty setting from the environment is kept" {
  # Arrange
  export BLUETOOTH_REVAMPED_SEPARATOR=

  # Act
  lib_run bluetooth 'printf "[%s]" "$(bluetooth_revamped_setting separator ", ")"'

  # Assert
  [[ "${output}" == "[]" ]]
}

@test "bluetooth - the tmux option wins over the default" {
  # Arrange
  option @bluetooth_revamped_format '<%s>'

  # Act
  lib_call bluetooth bluetooth_revamped_setting format %s

  # Assert
  [[ "${output}" == "<%s>" ]]
}

@test "bluetooth - each setting reads its own environment variable" {
  # Arrange
  export BLUETOOTH_REVAMPED_INTERVAL=7 BLUETOOTH_REVAMPED_FORMAT=f BLUETOOTH_REVAMPED_SEPARATOR=s

  # Act
  lib_run bluetooth 'bluetooth_revamped_setting interval 30; bluetooth_revamped_setting format x; bluetooth_revamped_setting separator y'

  # Assert
  [[ "${output}" == $'7\nf\ns' ]]
}

@test "bluetooth - an interval that is not a number falls back to 30" {
  # Arrange
  option @bluetooth_revamped_interval soon

  # Act
  lib_call bluetooth bluetooth_revamped_interval

  # Assert
  [[ "${output}" == "30" ]]
}

@test "bluetooth - the interval comes from the tmux option" {
  # Arrange
  option @bluetooth_revamped_interval 120

  # Act
  lib_call bluetooth bluetooth_revamped_interval

  # Assert
  [[ "${output}" == "120" ]]
}

@test "bluetooth - device joins the devices with the separator inside the format" {
  # Arrange
  option @bluetooth_revamped_separator ' | '
  option @bluetooth_revamped_format '[%s]'

  # Act
  lib_call bluetooth bluetooth_revamped_render_device $'AirPods Pro 85%\n\nMX Master 50%'

  # Assert
  [[ "${output}" == "[AirPods Pro 85% | MX Master 50%]" ]]
}

@test "bluetooth - a hash in a device name is doubled, since tmux expands a job's output, and one in the separator is left alone" {
  # Arrange
  option @bluetooth_revamped_separator '#[fg=red]|#[default]'

  # Act
  lib_call bluetooth bluetooth_revamped_render_device $'Desk#S Keys 80%\nPods ## 50%'

  # Assert
  [[ "${output}" == "Desk##S Keys 80%#[fg=red]|#[default]Pods #### 50%" ]]
}

@test "bluetooth - device prints an empty line with nothing connected" {
  # Arrange
  local devices=""

  # Act
  lib_run bluetooth "bluetooth_revamped_render_device '${devices}'; printf end"

  # Assert
  [[ "${output}" == $'\nend' ]]
}

@test "bluetooth - icon prints the icon while a device is connected" {
  # Arrange
  option @bluetooth_revamped_icon B

  # Act
  lib_call bluetooth bluetooth_revamped_render_icon "MX Master 50%"

  # Assert
  [[ "${output}" == "B" ]]
}

@test "bluetooth - icon is empty with nothing connected" {
  # Arrange
  option @bluetooth_revamped_icon B

  # Act
  lib_call bluetooth bluetooth_revamped_render_icon ""

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ -z "${output}" ]]
}

@test "bluetooth - count counts the devices" {
  # Arrange
  local devices=$'AirPods Pro 85%\n\nMagic Keyboard'

  # Act
  lib_call bluetooth bluetooth_revamped_render_count "${devices}"

  # Assert
  [[ "${output}" == "2" ]]
}

@test "bluetooth - count is 0 with nothing connected" {
  # Arrange
  local devices=""

  # Act
  lib_call bluetooth bluetooth_revamped_render_count "${devices}"

  # Assert
  [[ "${output}" == "0" ]]
}

@test "bluetooth - min picks the device with the lowest battery" {
  # Arrange
  local devices=$'AirPods Pro 85%\nMagic Keyboard\nMX Master 50%\nOdd 7x%\nPhone 090%'

  # Act
  lib_call bluetooth bluetooth_revamped_render_min "${devices}"

  # Assert
  [[ "${output}" == "MX Master 50%" ]]
}

@test "bluetooth - min is empty when no device reports a level" {
  # Arrange
  local devices="Magic Keyboard"

  # Act
  lib_call bluetooth bluetooth_revamped_render_min "${devices}"

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ -z "${output}" ]]
}

@test "bluetooth - refresh stores the reading in a tmux option" {
  # Arrange
  export REVAMPED_TEST_UNAME_S=Darwin
  dump 'Bluetooth:\n    Connected:\n        MX Master:\n            Battery Level: 50%\n'

  # Act
  lib_call bluetooth bluetooth_revamped_refresh

  # Assert
  stored @bluetooth_revamped_device
  [[ "${STORED}" == "MX Master 50%" ]]
  stored @bluetooth_revamped_device_ts
  [[ "${STORED}" == "1000000" ]]
}

@test "bluetooth - status prints a fresh reading without reading again" {
  # Arrange
  option @bluetooth_revamped_device "MX Master 50%"
  option @bluetooth_revamped_device_ts 999990

  # Act
  lib_call bluetooth bluetooth_revamped_status count

  # Assert
  [[ "${output}" == "1" ]]
  [[ ! -e "${REVAMPED_TEST_BLUETOOTH_LOG}" ]]
}

@test "bluetooth - status reads again once the reading is older than the interval" {
  # Arrange
  export REVAMPED_TEST_UNAME_S=Darwin REVAMPED_CACHE_SYNC=1
  dump 'Bluetooth:\n    Connected:\n        MX Master:\n            Battery Level: 50%\n'
  option @bluetooth_revamped_device "Old 10%"
  option @bluetooth_revamped_device_ts 999000

  # Act
  lib_call bluetooth bluetooth_revamped_status min

  # Assert
  [[ "${output}" == "MX Master 50%" ]]
  stored @bluetooth_revamped_device_lock
  [[ "${STORED}" == "0" ]]
}

@test "bluetooth - json prints each device with its battery or null" {
  # Arrange
  local devices=$'AirPods "Pro" 85%\nC:\\\\Keys\n\nTab\there 5%'

  # Act
  lib_run bluetooth "printf '%s\\n' '${devices}' | bluetooth_revamped_json"

  # Assert
  [[ "${output}" == '{"devices":[{"name":"AirPods \"Pro\"","battery":85},{"name":"C:\\\\Keys","battery":null},{"name":"Tab\there","battery":5}]}' ]]
}

@test "bluetooth - json prints an empty list with nothing connected" {
  # Arrange
  local devices=""

  # Act
  lib_run bluetooth "printf '%s\\n' '${devices}' | bluetooth_revamped_json"

  # Assert
  [[ "${output}" == '{"devices":[]}' ]]
}
