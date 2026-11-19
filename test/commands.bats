#!/usr/bin/env bats
# shellcheck disable=SC2016,SC2030,SC2031,SC2034

# shellcheck source=test/commands_helpers.bash
source "${BATS_TEST_DIRNAME:-.}/commands_helpers.bash"

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

@test "commands - doctor names a tmux option whose value it does not know" {
  # Arrange
  tmux set-option -g @bluetooth_revamped_low soon

  # Act
  tool doctor

  # Assert
  run grep '^settings' <<<"${output}"
  [[ "${output}" == "settings           warn     unknown values: low=soon" ]]
}
