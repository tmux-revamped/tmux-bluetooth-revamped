#!/usr/bin/env bats
# shellcheck disable=SC2016,SC2030,SC2031,SC2034

# shellcheck source=test/helpers.bash
source "${BATS_TEST_DIRNAME:-.}/helpers.bash"

setup() {
  harness_setup
  unset BLUETOOTH_REVAMPED_INTERVAL BLUETOOTH_REVAMPED_NOTIFY BLUETOOTH_REVAMPED_POPUP_KEY
  export REVAMPED_TEST_NOW=1000000 REVAMPED_TEST_BLUETOOTH_LOG="${BATS_TEST_TMPDIR}/readers.log"
  export REVAMPED_TEST_BLUETOOTH_DUMP="${BATS_TEST_TMPDIR}/dump"
}

macos() {
  export REVAMPED_TEST_UNAME_S=Darwin
  printf 'Bluetooth:\n      Connected:\n          MX Master 3S:\n              Address: AA:BB:CC:00:00:02\n              Battery Level: 50%%\n      Not Connected:\n          Magic Keyboard:\n              Address: AA:BB:CC:00:00:03\n' >"${REVAMPED_TEST_BLUETOOTH_DUMP}"
}

linux() {
  export REVAMPED_TEST_UNAME_S=Linux REVAMPED_TEST_BLUETOOTH_PAIRED="${BATS_TEST_TMPDIR}/paired"
  printf 'Device AA:BB:CC:00:00:01 WH-1000XM4\n' >"${REVAMPED_TEST_BLUETOOTH_PAIRED}"
  : >"${REVAMPED_TEST_BLUETOOTH_DUMP}"
}

act() {
  lib_run actions "$1"' ; printf "problem=%s\n" "${BLUETOOTH_REVAMPED_PROBLEM}"; printf "done=%s\n" "${BLUETOOTH_REVAMPED_DONE}"'
}

@test "actions - connect on macOS runs blueutil with the device's address" {
  # Arrange
  macos

  # Act
  act 'bluetooth_revamped_action connect "Magic Keyboard"'

  # Assert
  [[ "${output}" == $'problem=\ndone=Magic Keyboard is connected.' ]]
  grep -qx 'blueutil --connect AA:BB:CC:00:00:03' "${REVAMPED_TEST_BLUETOOTH_LOG}"
}

@test "actions - a device can be named by its address in any case" {
  # Arrange
  macos

  # Act
  act 'bluetooth_revamped_action disconnect aa:bb:cc:00:00:02'

  # Assert
  [[ "${output}" == $'problem=\ndone=MX Master 3S is disconnected.' ]]
  grep -qx 'blueutil --disconnect AA:BB:CC:00:00:02' "${REVAMPED_TEST_BLUETOOTH_LOG}"
}

@test "actions - connect on Linux runs bluetoothctl" {
  # Arrange
  linux

  # Act
  act 'bluetooth_revamped_action connect WH-1000XM4'

  # Assert
  [[ "${output}" == $'problem=\ndone=WH-1000XM4 is connected.' ]]
  grep -qx 'bluetoothctl connect AA:BB:CC:00:00:01' "${REVAMPED_TEST_BLUETOOTH_LOG}"
}

@test "actions - an unknown device is a problem" {
  # Arrange
  macos

  # Act
  act 'bluetooth_revamped_action connect Toaster'

  # Assert
  [[ "${output}" == $'problem=no paired device is named or addressed \'Toaster\'\ndone=' ]]
}

@test "actions - a tool that fails is a problem" {
  # Arrange
  macos
  export REVAMPED_TEST_BLUETOOTH_FAIL=1

  # Act
  act 'bluetooth_revamped_action connect "Magic Keyboard"'

  # Assert
  [[ "${output}" == $'problem=blueutil could not connect Magic Keyboard\ndone=' ]]
}

@test "actions - a missing tool names the way to install it" {
  # Arrange
  macos
  harness_hide blueutil

  # Act
  act 'bluetooth_revamped_action connect "Magic Keyboard"'

  # Assert
  [[ "${output}" == $'problem=connect needs blueutil. install it with: brew install blueutil\ndone=' ]]
}

@test "actions - a missing tool on Linux names bluez" {
  # Arrange
  linux
  harness_hide bluetoothctl

  # Act
  act 'bluetooth_revamped_power on'

  # Assert
  [[ "${output}" == $'problem=power needs bluetoothctl. install it with: apt install bluez\ndone=' ]]
}

@test "actions - power on and off on macOS" {
  # Arrange
  macos

  # Act
  act 'bluetooth_revamped_power off; bluetooth_revamped_power on'

  # Assert
  [[ "${output}" == $'problem=\ndone=Bluetooth is on.' ]]
  grep -qx 'blueutil --power 0' "${REVAMPED_TEST_BLUETOOTH_LOG}"
  grep -qx 'blueutil --power 1' "${REVAMPED_TEST_BLUETOOTH_LOG}"
}

@test "actions - toggle turns Bluetooth off when it is on, on macOS" {
  # Arrange
  macos
  export REVAMPED_TEST_BLUETOOTH_POWER=1

  # Act
  act 'bluetooth_revamped_power toggle'

  # Assert
  [[ "${output}" == $'problem=\ndone=Bluetooth is off.' ]]
}

@test "actions - toggle turns Bluetooth on when it is off, on Linux" {
  # Arrange
  linux
  export REVAMPED_TEST_BLUETOOTH_POWER=0

  # Act
  act 'bluetooth_revamped_power toggle'

  # Assert
  [[ "${output}" == $'problem=\ndone=Bluetooth is on.' ]]
  grep -qx 'bluetoothctl power on' "${REVAMPED_TEST_BLUETOOTH_LOG}"
}

@test "actions - a power switch that fails is a problem" {
  # Arrange
  linux
  export REVAMPED_TEST_BLUETOOTH_FAIL=1

  # Act
  act 'bluetooth_revamped_power off'

  # Assert
  [[ "${output}" == $'problem=bluetoothctl could not turn Bluetooth off\ndone=' ]]
}

@test "actions - the power state reads on and off on both systems" {
  # Arrange
  export REVAMPED_TEST_BLUETOOTH_POWER=0

  # Act
  lib_run actions 'export REVAMPED_TEST_UNAME_S=Darwin; bluetooth_revamped_power_state; export REVAMPED_TEST_UNAME_S=Linux REVAMPED_TEST_BLUETOOTH_POWER=1; bluetooth_revamped_power_state'

  # Assert
  [[ "${output}" == $'off\non' ]]
}

@test "actions - names lists the devices in one state" {
  # Arrange
  macos

  # Act
  lib_run actions 'bluetooth_revamped_collect; bluetooth_revamped_names paired'

  # Assert
  [[ "${output}" == "Magic Keyboard" ]]
}

@test "actions - the popup key comes from its setting" {
  # Arrange
  export BLUETOOTH_REVAMPED_POPUP_KEY=M-y

  # Act
  lib_call actions bluetooth_revamped_popup_key

  # Assert
  [[ "${output}" == "M-y" ]]
}
