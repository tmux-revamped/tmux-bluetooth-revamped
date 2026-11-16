#!/usr/bin/env bats
# shellcheck disable=SC2016,SC2030,SC2031,SC2034

# shellcheck source=test/helpers.bash
source "${BATS_TEST_DIRNAME:-.}/helpers.bash"

setup() {
  harness_setup
  unset KODOUGU_THEME KODOUGU_ACCENT NO_COLOR BLUETOOTH_REVAMPED_THEME BLUETOOTH_REVAMPED_ACCENT
  unset BLUETOOTH_REVAMPED_INTERVAL BLUETOOTH_REVAMPED_FORMAT BLUETOOTH_REVAMPED_SEPARATOR BLUETOOTH_REVAMPED_ICON
  export REVAMPED_TEST_NOW=1000000 REVAMPED_TEST_UNAME_S=Darwin
  export REVAMPED_TEST_BLUETOOTH_DUMP="${BATS_TEST_TMPDIR}/dump"
  printf 'Bluetooth:\n    Connected:\n        AirPods Pro:\n            Battery Level: 85%%\n        MX Master:\n            Battery Level: 50%%\n' >"${REVAMPED_TEST_BLUETOOTH_DUMP}"
}

tool() {
  # shellcheck disable=SC2086
  run ${REVAMPED_TEST_SHELL:-sh} "${REVAMPED_TESTS_DIR}/../bin/bluetooth-revamped" "$@"
}

lock_released() {
  local key file
  key=$(printf '%s' "g.-.@bluetooth_revamped_device_lock" | tr -c 'A-Za-z0-9_.-' '_')
  file="${REVAMPED_TEST_TMUX_DIR}/${key}"
  [[ -f "${file}" ]] && [[ "$(<"${file}")" == "0" ]]
}

stored_reading() {
  # shellcheck disable=SC2086
  ${REVAMPED_TEST_SHELL:-sh} "${REVAMPED_TESTS_DIR}/../bin/bluetooth-revamped" refresh >/dev/null
}

one_device() {
  printf 'Bluetooth:\n    Connected:\n        MX Master:\n            Battery Level: 50%%\n' >"${REVAMPED_TEST_BLUETOOTH_DUMP}"
}

@test "commands - status device prints every device" {
  # Arrange
  local name=device
  stored_reading

  # Act
  tool status "${name}"

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == "AirPods Pro 85%, MX Master 50%" ]]
}

@test "commands - status icon, count and min print their placeholders" {
  # Arrange
  stored_reading
  tool status icon
  local icon="${output}"
  tool status count
  local count="${output}"

  # Act
  tool status min

  # Assert
  [[ "${icon}" == "BT" ]]
  [[ "${count}" == "2" ]]
  [[ "${output}" == "MX Master 50%" ]]
}

@test "commands - status without a name is a usage error" {
  # Arrange
  local command=status

  # Act
  tool "${command}"

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == "bluetooth-revamped: no placeholder given. run 'bluetooth-revamped help' for usage." ]]
}

@test "commands - status with an unknown name is a bad value" {
  # Arrange
  local name=battery

  # Act
  tool status "${name}"

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == "bluetooth-revamped: status must be device, icon, count or min, got: battery" ]]
}

@test "commands - options in both forms change what status prints" {
  # Arrange
  local separator=' | '
  stored_reading

  # Act
  tool --separator "${separator}" --format='<%s>' status device

  # Assert
  [[ "${output}" == "<AirPods Pro 85% | MX Master 50%>" ]]
}

@test "commands - an option wins over the environment" {
  # Arrange
  stored_reading
  export BLUETOOTH_REVAMPED_ICON=env

  # Act
  tool --icon=flag status icon

  # Assert
  [[ "${output}" == "flag" ]]
}

@test "commands - the environment wins over the tmux option" {
  # Arrange
  stored_reading
  export BLUETOOTH_REVAMPED_ICON=env
  printf 'tmux' >"${REVAMPED_TEST_TMUX_DIR}/g.-._bluetooth_revamped_icon"

  # Act
  tool status icon

  # Assert
  [[ "${output}" == "env" ]]
}

@test "commands - -- ends the options" {
  # Arrange
  local name=device
  stored_reading

  # Act
  tool -- status "${name}"

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == "AirPods Pro 85%, MX Master 50%" ]]
}

@test "commands - an option without its value is a usage error" {
  # Arrange
  local option=--icon

  # Act
  tool status icon "${option}"

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == "bluetooth-revamped: option '--icon' needs a value. run 'bluetooth-revamped help' for usage." ]]
}

@test "commands - an unknown option is a usage error before any reading" {
  # Arrange
  local option=--loud

  # Act
  tool "${option}" status device

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == "bluetooth-revamped: unknown option '--loud'. run 'bluetooth-revamped help' for usage." ]]
}

@test "commands - an interval that is not a number is a bad value" {
  # Arrange
  local interval=soon

  # Act
  tool --interval "${interval}" status device

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == "bluetooth-revamped: --interval must be a whole number of seconds, got: soon" ]]
}

@test "commands - an interval from the environment is checked too" {
  # Arrange
  export BLUETOOTH_REVAMPED_INTERVAL=1m

  # Act
  tool status device

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == "bluetooth-revamped: --interval must be a whole number of seconds, got: 1m" ]]
}

@test "commands - an interval of 3600 keeps a reading for an hour" {
  # Arrange
  tool refresh
  one_device
  export REVAMPED_TEST_NOW=1003000

  # Act
  tool --interval 3600 status count

  # Assert
  [[ "${output}" == "2" ]]
}

@test "commands - list prints one device per line" {
  # Arrange
  local command=list

  # Act
  tool "${command}"

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == $'AirPods Pro 85%\nMX Master 50%' ]]
}

@test "commands - list prints nothing with nothing connected" {
  # Arrange
  : >"${REVAMPED_TEST_BLUETOOTH_DUMP}"

  # Act
  tool list

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ -z "${output}" ]]
}

@test "commands - list --json prints one JSON object" {
  # Arrange
  local flag=--json

  # Act
  tool list "${flag}"

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == '{"devices":[{"name":"AirPods Pro","battery":85},{"name":"MX Master","battery":50}]}' ]]
}

@test "commands - --json with any command but list is a usage error" {
  # Arrange
  local flag=--json

  # Act
  tool "${flag}" status device

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == "bluetooth-revamped: option '--json' works only with list. run 'bluetooth-revamped help' for usage." ]]
}

@test "commands - refresh reads now and says how many devices are connected" {
  # Arrange
  local command=refresh

  # Act
  tool "${command}"

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == "Refreshed. 2 devices are connected." ]]
}

@test "commands - refresh says one device in the singular" {
  # Arrange
  one_device

  # Act
  tool refresh

  # Assert
  [[ "${output}" == "Refreshed. 1 device is connected." ]]
}

@test "commands - doctor checks upower on Linux" {
  # Arrange
  export REVAMPED_TEST_UNAME_S=Linux

  # Act
  tool doctor

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" =~ upower\ +ok ]]
}

@test "commands - doctor exits 1 on Linux without upower" {
  # Arrange
  export REVAMPED_TEST_UNAME_S=Linux
  harness_hide upower

  # Act
  tool doctor

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" =~ upower\ +missing\ +apt\ install\ upower ]]
}

@test "commands - doctor checks system_profiler on macOS" {
  # Arrange
  local command=doctor

  # Act
  tool "${command}"

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" =~ system_profiler\ +ok ]]
}

@test "commands - doctor warns on a system with no Bluetooth reader" {
  # Arrange
  export REVAMPED_TEST_UNAME_S=FreeBSD

  # Act
  tool doctor

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" =~ source\ +warn\ +no\ Bluetooth\ reader ]]
}

@test "commands - an inherited internal variable of the plugin is ignored" {
  # Arrange
  export BLUETOOTH_REVAMPED_CORE_LOADED=1 BLUETOOTH_REVAMPED_DEFAULT_ICON=fake

  # Act
  tool version

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${lines[0]}" =~ ^bluetooth-revamped\ [0-9]+\.[0-9]+\.[0-9]+$ ]]
}

@test "commands - status starts a background reading and the next call shows it" {
  # Arrange
  local wait=0.01 tries=0
  tool status count

  # Act
  until lock_released || [[ "${tries}" -ge 12 ]]; do
    sleep "${wait}"
    wait=$(awk -v w="${wait}" 'BEGIN { print w * 2 }')
    tries=$((tries + 1))
  done

  # Assert
  [[ "${output}" == "0" ]]
  tool status count
  [[ "${output}" == "2" ]]
}

@test "commands - status renders empty when no tmux server answers" {
  # Arrange
  export REVAMPED_TEST_TMUX_FAIL=1

  # Act
  tool status device

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ -z "${output}" ]]
}

@test "commands - list still prints the devices when no tmux server answers" {
  # Arrange
  export REVAMPED_TEST_TMUX_FAIL=1

  # Act
  tool list

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" == $'AirPods Pro 85%\nMX Master 50%' ]]
}

@test "commands - refresh says why it fails when no tmux server answers" {
  # Arrange
  export REVAMPED_TEST_TMUX_FAIL=1

  # Act
  tool refresh

  # Assert
  [[ "${status}" -eq 1 ]]
  [[ "${output}" == "bluetooth-revamped: no tmux server is running, so the reading has nowhere to go" ]]
}

paired_dump() {
  printf 'Bluetooth:\n      Connected:\n          MX Master:\n              Address: AA:BB:CC:00:00:02\n              Battery Level: 50%%\n      Not Connected:\n          Magic Keyboard:\n              Address: AA:BB:CC:00:00:03\n' >"${REVAMPED_TEST_BLUETOOTH_DUMP}"
}

gum_answers() {
  export REVAMPED_TEST_GUM=1 REVAMPED_TEST_GUM_LOG="${BATS_TEST_TMPDIR}/gum.log" REVAMPED_TEST_GUM_ANSWERS="${BATS_TEST_TMPDIR}/answers"
  : >"${REVAMPED_TEST_GUM_LOG}"
  printf '%s\n' "$@" >"${REVAMPED_TEST_GUM_ANSWERS}"
}

plain_tty() {
  local shell_words
  read -r -a shell_words <<<"${REVAMPED_TEST_SHELL:-sh}"
  run python3 "${REVAMPED_TESTS_DIR}/on_tty.py" "${shell_words[@]}" "${REVAMPED_TESTS_DIR}/../bin/bluetooth-revamped" "$@"
}

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
