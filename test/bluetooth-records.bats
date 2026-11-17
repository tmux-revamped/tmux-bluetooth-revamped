#!/usr/bin/env bats
# shellcheck disable=SC2016,SC2030,SC2031,SC2034

# shellcheck source=test/bluetooth_helpers.bash
source "${BATS_TEST_DIRNAME:-.}/bluetooth_helpers.bash"

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
