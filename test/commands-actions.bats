#!/usr/bin/env bats
# shellcheck disable=SC2016,SC2030,SC2031,SC2034

# shellcheck source=test/commands_helpers.bash
source "${BATS_TEST_DIRNAME:-.}/commands_helpers.bash"

@test "commands - connect connects a paired device and says so" {
  # Arrange
  paired_dump

  # Act
  tool connect Magic Keyboard

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == "Magic Keyboard is connected." ]]
}

@test "commands - disconnect without a device is a usage error" {
  # Arrange
  local command=disconnect

  # Act
  tool "${command}"

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == "bluetooth-revamped: no device given. run 'bluetooth-revamped help' for usage." ]]
}

@test "commands - connect names a device it does not know" {
  # Arrange
  paired_dump

  # Act
  tool connect Toaster

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == "bluetooth-revamped: no paired device is named or addressed 'Toaster'" ]]
}

@test "commands - power on, off and toggle say the new state" {
  # Arrange
  export REVAMPED_TEST_BLUETOOTH_POWER=1

  # Act
  tool power toggle

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == "Bluetooth is off." ]]
}

@test "commands - power without a state is a usage error" {
  # Arrange
  local command=power

  # Act
  tool "${command}"

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == "bluetooth-revamped: no power state given. run 'bluetooth-revamped help' for usage." ]]
}

@test "commands - power with an unknown state is a bad value" {
  # Arrange
  local state=maybe

  # Act
  tool power "${state}"

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == "bluetooth-revamped: power must be on, off or toggle, got: maybe" ]]
}

@test "commands - power without blueutil says how to install it" {
  # Arrange
  harness_hide blueutil

  # Act
  tool power on

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == "bluetooth-revamped: power needs blueutil. install it with: brew install blueutil" ]]
}

@test "commands - a closing sentence is drawn where gum draws" {
  # Arrange
  gum_answers

  # Act
  tool power on

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == *"Bluetooth is on."* ]]
}

@test "commands - the popup lists the devices and connects the one picked" {
  # Arrange
  paired_dump
  export REVAMPED_TEST_BLUETOOTH_LOG="${BATS_TEST_TMPDIR}/readers.log"
  gum_answers "Connect a device" "Magic Keyboard"

  # Act
  tool popup

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == *"MX Master"* ]]
  [[ "${output}" == *"Magic Keyboard is connected."* ]]
  grep -qx 'blueutil --connect AA:BB:CC:00:00:03' "${REVAMPED_TEST_BLUETOOTH_LOG}"
}

@test "commands - the popup disconnects a connected device" {
  # Arrange
  paired_dump
  gum_answers "Disconnect a device" "MX Master"

  # Act
  tool popup

  # Assert
  [[ "${output}" == *"MX Master is disconnected."* ]]
}

@test "commands - the popup turns Bluetooth off while it is on and on while it is off" {
  # Arrange
  export REVAMPED_TEST_BLUETOOTH_POWER=0
  gum_answers "Turn Bluetooth on"

  # Act
  tool popup

  # Assert
  [[ "${output}" == *"Bluetooth is on."* ]]
  grep -q -- 'Turn Bluetooth on' "${REVAMPED_TEST_GUM_LOG}"
}

@test "commands - the popup offers to turn Bluetooth off while it is on" {
  # Arrange
  export REVAMPED_TEST_BLUETOOTH_POWER=1
  gum_answers "Turn Bluetooth off"

  # Act
  tool popup

  # Assert
  [[ "${output}" == *"Bluetooth is off."* ]]
}

@test "commands - the popup closes on Close" {
  # Arrange
  gum_answers "Close"

  # Act
  tool popup

  # Assert
  [[ "${status}" -eq 0 ]]
}

@test "commands - the popup refuses to pick from no devices" {
  # Arrange
  : >"${REVAMPED_TEST_BLUETOOTH_DUMP}"
  gum_answers "Connect a device"

  # Act
  tool popup

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == *"no device to choose from"* ]]
}

@test "commands - a cancelled device choice exits 1" {
  # Arrange
  paired_dump
  gum_answers "Connect a device" "<cancel>"

  # Act
  tool popup

  # Assert
  [[ "${status}" -eq 1 ]]
}

@test "commands - the plain popup numbers the actions and the devices" {
  # Arrange
  paired_dump
  harness_hide gum

  # Act
  plain_tty popup <<<$'1\n1'

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == *"Which device?"* ]]
  [[ "${output}" == *"Magic Keyboard is connected."* ]]
  [[ "${output}" =~ Magic\ Keyboard\ +paired ]]
}

@test "commands - the menu opens the device manager" {
  # Arrange
  gum_answers "Manage the devices" "Close"

  # Act
  tool

  # Assert
  [[ "${status}" -eq 0 ]]
}

@test "commands - icons and notify take only 0 or 1" {
  # Arrange
  local value=yes

  # Act
  tool --icons "${value}" status device

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == "bluetooth-revamped: --icons must be 0 or 1, got: yes" ]]
}

@test "commands - notify from the environment is checked too" {
  # Arrange
  export BLUETOOTH_REVAMPED_NOTIFY=on

  # Act
  tool status device

  # Assert
  [[ "${output}" == "bluetooth-revamped: --notify must be 0 or 1, got: on" ]]
}

@test "commands - a low level that is not a number is a bad value" {
  # Arrange
  local low=half

  # Act
  tool --low="${low}" status device

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == "bluetooth-revamped: --low must be a whole number of percent, got: half" ]]
}

@test "commands - the new options are accepted" {
  # Arrange
  stored_reading

  # Act
  tool --icons 0 --notify=1 --low 10 --popup-key M-y status count

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == "2" ]]
}

@test "commands - doctor warns when the tool for the actions is missing" {
  # Arrange
  harness_hide blueutil

  # Act
  tool doctor

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" =~ blueutil\ +warn\ +connect,\ disconnect\ and\ power\ need\ it:\ brew\ install\ blueutil ]]
}

@test "commands - doctor warns when the popup key is already bound" {
  # Arrange
  mkdir -p "${BATS_TEST_TMPDIR}/stubs"
  printf '#!/bin/sh\nif [ "$1" = list-keys ]; then printf "bind-key -T prefix M-h split-window\\n"; exit 0; fi\nexec "%s/bin/tmux" "$@"\n' "${REVAMPED_TESTS_DIR}" >"${BATS_TEST_TMPDIR}/stubs/tmux"
  chmod +x "${BATS_TEST_TMPDIR}/stubs/tmux"

  # Act
  tool doctor

  # Assert
  [[ "${output}" =~ prefix\ M-h\ +warn\ +already\ bound ]]
}

@test "commands - doctor has no key row when the popup key is none" {
  # Arrange
  export BLUETOOTH_REVAMPED_POPUP_KEY=none

  # Act
  tool doctor

  # Assert
  [[ "${output}" != *"prefix "* ]]
}
