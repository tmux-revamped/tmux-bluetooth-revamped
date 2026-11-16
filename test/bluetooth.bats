#!/usr/bin/env bats
# shellcheck disable=SC2016,SC2030,SC2031,SC2034

# shellcheck source=test/helpers.bash
source "${BATS_TEST_DIRNAME:-.}/helpers.bash"

setup() {
  harness_setup
  unset BLUETOOTH_REVAMPED_INTERVAL BLUETOOTH_REVAMPED_FORMAT BLUETOOTH_REVAMPED_SEPARATOR BLUETOOTH_REVAMPED_ICON
  export REVAMPED_TEST_NOW=1000000 REVAMPED_TEST_BLUETOOTH_LOG="${BATS_TEST_TMPDIR}/readers.log"
  DUMP="${BATS_TEST_TMPDIR}/dump"
}

dump() {
  printf '%b' "$1" >"${DUMP}"
  export REVAMPED_TEST_BLUETOOTH_DUMP="${DUMP}"
}

parse() {
  dump "$2"
  lib_run bluetooth "bluetooth_revamped_parse_$1 <\"${DUMP}\""
}

option() {
  printf '%s' "$2" >"${REVAMPED_TEST_TMUX_DIR}/$(printf '%s' "g.-.$1" | tr -c 'A-Za-z0-9_.-' '_')"
}

stored() {
  local key
  key=$(printf '%s' "g.-.$1" | tr -c 'A-Za-z0-9_.-' '_')
  STORED=$(<"${REVAMPED_TEST_TMUX_DIR}/${key}")
}

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

macos_dump() {
  dump 'Bluetooth:\n      Bluetooth Controller:\n          Address: 00:00:00:00:00:00\n          State: On\n      Connected:\n          AirPods Pro:\n              Address: AA:BB:CC:00:00:01\n              Left Battery Level: 90%\n              Right Battery Level: 15%\n              Minor Type: Headphones\n          MX Master 3S:\n              Address: AA:BB:CC:00:00:02\n              Battery Level: 50%\n              Minor Type: Mouse\n      Not Connected:\n          Magic Keyboard:\n              Address: AA:BB:CC:00:00:03\n              Minor Type: Keyboard\n'
}

linux_dumps() {
  export REVAMPED_TEST_BLUETOOTH_PAIRED="${BATS_TEST_TMPDIR}/paired" REVAMPED_TEST_BLUETOOTH_CONNECTED="${BATS_TEST_TMPDIR}/connected"
  printf 'Device AA:BB:CC:00:00:01 WH-1000XM4\nDevice AA:BB:CC:00:00:02 MX Master 3S\nDevice AA:BB:CC:00:00:03 Pad\n' >"${REVAMPED_TEST_BLUETOOTH_PAIRED}"
  printf 'Device AA:BB:CC:00:00:01 WH-1000XM4\n' >"${REVAMPED_TEST_BLUETOOTH_CONNECTED}"
  dump 'Device: /org/freedesktop/UPower/devices/headset_dev_AA_BB_CC_00_00_01\n  native-path:          /org/bluez/hci0/dev_AA_BB_CC_00_00_01\n  model:                WH-1000XM4\n  headset\n    percentage:          80%\nDevice: /org/freedesktop/UPower/devices/battery_BAT0\n  native-path:          BAT0\n  battery\n    percentage:          64%\n'
}

@test "bluetooth - macOS records every paired device with its state, address, type and battery" {
  # Arrange
  export REVAMPED_TEST_UNAME_S=Darwin
  macos_dump

  # Act
  lib_run bluetooth 'bluetooth_revamped_records "$(cat "${REVAMPED_TEST_BLUETOOTH_DUMP}")"'

  # Assert
  [[ "${lines[0]}" == $'connected\tAA:BB:CC:00:00:01\theadphones\t15\tAirPods Pro' ]]
  [[ "${lines[1]}" == $'connected\tAA:BB:CC:00:00:02\tmouse\t50\tMX Master 3S' ]]
  [[ "${lines[2]}" == $'paired\tAA:BB:CC:00:00:03\tkeyboard\t\tMagic Keyboard' ]]
  [[ "${#lines[@]}" -eq 3 ]]
}

@test "bluetooth - macOS names every kind of device it knows" {
  # Arrange
  export REVAMPED_TEST_UNAME_S=Darwin
  dump 'Bluetooth:\n      Connected:\n          A:\n              Minor Type: Gamepad\n          B:\n              Minor Type: Speaker\n          C:\n              Minor Type: Smartphone\n          D:\n              Minor Type: Watch\n          E:\n              Minor Type: Toaster\n          F:\n              Case Battery Level: 70%\n'

  # Act
  lib_run bluetooth 'bluetooth_revamped_records "$(cat "${REVAMPED_TEST_BLUETOOTH_DUMP}")" | cut -f 3,4'

  # Assert
  [[ "${output}" == $'gamepad\t\nspeaker\t\nphone\t\nwatch\t\nother\t\nother\t70' ]]
}

@test "bluetooth - Linux records paired devices from bluetoothctl with upower's kind and battery" {
  # Arrange
  export REVAMPED_TEST_UNAME_S=Linux
  linux_dumps

  # Act
  lib_run bluetooth 'bluetooth_revamped_records "$(cat "${REVAMPED_TEST_BLUETOOTH_DUMP}")"'

  # Assert
  [[ "${lines[0]}" == $'connected\tAA:BB:CC:00:00:01\theadphones\t80\tWH-1000XM4' ]]
  [[ "${lines[1]}" == $'paired\tAA:BB:CC:00:00:02\tother\t\tMX Master 3S' ]]
  [[ "${lines[2]}" == $'paired\tAA:BB:CC:00:00:03\tother\t\tPad' ]]
}

@test "bluetooth - Linux names every kind upower reports" {
  # Arrange
  local kinds="mouse touchpad keyboard gaming-input speakers phone headphones"
  local kind

  # Act
  for kind in ${kinds}; do
    printf 'Device AA:BB:CC:00:00:09 X\n== connected\n== upower\nDevice: x\n  native-path: /org/bluez/hci0/dev_AA_BB_CC_00_00_09\n  %s\n' "${kind}"
  done >"${BATS_TEST_TMPDIR}/kinds"
  lib_run bluetooth "while IFS= read -r a && IFS= read -r b && IFS= read -r c && IFS= read -r d && IFS= read -r e && IFS= read -r f; do printf '%s\n' \"\$a\" \"\$b\" \"\$c\" \"\$d\" \"\$e\" \"\$f\" | bluetooth_revamped_records_linux | cut -f 3; done <'${BATS_TEST_TMPDIR}/kinds'"

  # Assert
  [[ "${output}" == $'mouse\nmouse\nkeyboard\ngamepad\nspeaker\nphone\nheadphones' ]]
}

@test "bluetooth - Linux has no records without bluetoothctl" {
  # Arrange
  export REVAMPED_TEST_UNAME_S=Linux
  harness_hide bluetoothctl

  # Act
  lib_run bluetooth 'bluetooth_revamped_records anything'

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ -z "${output}" ]]
}

@test "bluetooth - refresh stores the records next to the device list" {
  # Arrange
  export REVAMPED_TEST_UNAME_S=Darwin
  macos_dump

  # Act
  lib_call bluetooth bluetooth_revamped_refresh

  # Assert
  stored @bluetooth_revamped_details
  [[ "${STORED}" == *$'connected\tAA:BB:CC:00:00:02\tmouse\t50\tMX Master 3S'* ]]
  stored @bluetooth_revamped_device
  [[ "${STORED}" == $'AirPods Pro 15%\nMX Master 3S 50%' ]]
}

@test "bluetooth - refresh stores nothing more when no tmux server answers" {
  # Arrange
  export REVAMPED_TEST_UNAME_S=Darwin REVAMPED_TEST_TMUX_FAIL=1
  macos_dump

  # Act
  lib_run bluetooth 'bluetooth_revamped_refresh; printf "%s\n" "${BLUETOOTH_REVAMPED_STORED}"'

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == "0" ]]
}

@test "bluetooth - icons put each device's glyph before it" {
  # Arrange
  option @bluetooth_revamped_icons 1
  option @bluetooth_revamped_details $'connected\tA1\theadphones\t15\tAirPods Pro\nconnected\tA2\tmouse\t50\tMX Master 3S'

  # Act
  lib_call bluetooth bluetooth_revamped_render_device $'AirPods Pro 15%\nMX Master 3S 50%\nStranger'

  # Assert
  [[ "${output}" == $'\363\260\213\213 AirPods Pro 15%, \363\260\215\275 MX Master 3S 50%, \363\260\202\257 Stranger' ]]
}

@test "bluetooth - icons know every kind of device" {
  # Arrange
  option @bluetooth_revamped_icons 1
  option @bluetooth_revamped_separator '|'
  option @bluetooth_revamped_details $'connected\tA\tkeyboard\t\tK\nconnected\tB\tgamepad\t\tG\nconnected\tC\tspeaker\t\tS\nconnected\tD\tphone\t\tP\nconnected\tE\twatch\t\tW\nbroken'

  # Act
  lib_call bluetooth bluetooth_revamped_render_device $'K\nG\nS\nP\nW'

  # Assert
  [[ "${output}" == $'\363\260\214\214 K|\363\260\212\227 G|\363\260\223\203 S|\363\260\217\262 P|\363\260\226\211 W' ]]
}

@test "bluetooth - a low battery sends one notification while it stays low" {
  # Arrange
  export REVAMPED_TEST_UNAME_S=Darwin BLUETOOTH_REVAMPED_NOTIFY=1
  stub_command osascript
  macos_dump
  lib_call bluetooth bluetooth_revamped_refresh

  # Act
  lib_call bluetooth bluetooth_revamped_refresh

  # Assert
  run stub_calls osascript
  local sent
  sent=$(grep -c 'is at' <<<"${output}")
  [[ "${sent}" -eq 1 ]]
  [[ "${output}" == *"Bluetooth battery low"* ]]
  [[ "${output}" == *"AirPods Pro is at 15%."* ]]
  stored @bluetooth_revamped_notified
  [[ "${STORED}" == "AirPods Pro" ]]
}

@test "bluetooth - a battery that recovers can notify again later" {
  # Arrange
  export REVAMPED_TEST_UNAME_S=Darwin BLUETOOTH_REVAMPED_NOTIFY=1 BLUETOOTH_REVAMPED_LOW=10
  stub_command osascript
  option @bluetooth_revamped_notified "AirPods Pro"
  macos_dump

  # Act
  lib_call bluetooth bluetooth_revamped_refresh

  # Assert
  [[ ! -e "${BATS_TEST_TMPDIR}/osascript.calls" ]]
  stored @bluetooth_revamped_notified
  [[ -z "${STORED}" ]]
}

@test "bluetooth - no notification while notifications are off" {
  # Arrange
  export REVAMPED_TEST_UNAME_S=Darwin
  stub_command osascript
  macos_dump

  # Act
  lib_call bluetooth bluetooth_revamped_refresh

  # Assert
  [[ ! -e "${BATS_TEST_TMPDIR}/osascript.calls" ]]
}

@test "bluetooth - a low level that is not a number means 20" {
  # Arrange
  option @bluetooth_revamped_low lots

  # Act
  lib_call bluetooth bluetooth_revamped_low

  # Assert
  [[ "${output}" == "20" ]]
}

@test "bluetooth - an empty separator or format option means the default" {
  # Arrange
  option @bluetooth_revamped_separator ''
  option @bluetooth_revamped_format ''

  # Act
  lib_call bluetooth bluetooth_revamped_render_device $'A 1%\nB 2%'

  # Assert
  [[ "${output}" == "A 1%, B 2%" ]]
}

@test "bluetooth - device renders with the defaults when no tmux server answers" {
  # Arrange
  export REVAMPED_TEST_TMUX_FAIL=1

  # Act
  lib_call bluetooth bluetooth_revamped_render_device $'A 1%\nB 2%'

  # Assert
  [[ "${output}" == "A 1%, B 2%" ]]
}

@test "bluetooth - the environment wins over the options the renderer reads" {
  # Arrange
  option @bluetooth_revamped_separator ' / '
  export BLUETOOTH_REVAMPED_SEPARATOR='+' BLUETOOTH_REVAMPED_FORMAT='<%s>' BLUETOOTH_REVAMPED_ICONS=0

  # Act
  lib_call bluetooth bluetooth_revamped_render_device $'A 1%\nB 2%'

  # Assert
  [[ "${output}" == "<A 1%+B 2%>" ]]
}
