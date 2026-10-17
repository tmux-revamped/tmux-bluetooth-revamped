#!/usr/bin/env bats

load "${BATS_TEST_DIRNAME}/../../helpers.bash"

setup() {
  setup_test_environment
  unset _BLUETOOTH_REVAMPED_BLUETOOTH_LOADED _BLUETOOTH_REVAMPED_RENDER_LOADED
  export CACHE_SYNC=1
  source "${BATS_TEST_DIRNAME}/../../../src/bluetooth.sh"
  read_bluetooth() { echo "AirPods 85%"; }
}

teardown() {
  cleanup_test_environment
}

@test "bluetooth.sh dispatcher - functions are defined" {
  function_exists main
  function_exists bluetooth_refresh
  function_exists bluetooth_tick
  function_exists bluetooth_max_age
}

@test "bluetooth.sh dispatcher - bluetooth_max_age default is 30" {
  [[ "$(bluetooth_max_age)" == "30" ]]
}

@test "bluetooth.sh dispatcher - bluetooth_max_age honors the interval option" {
  set_tmux_option "@bluetooth_revamped_interval" "60"
  [[ "$(bluetooth_max_age)" == "60" ]]
}

@test "bluetooth.sh dispatcher - bluetooth_refresh caches the device" {
  bluetooth_refresh
  [[ "$(cache_get device)" == "AirPods 85%" ]]
}

@test "bluetooth.sh dispatcher - refresh subcommand caches the device" {
  main refresh
  [[ "$(cache_get device)" == "AirPods 85%" ]]
}

@test "bluetooth.sh dispatcher - device subcommand renders the cached value" {
  run main device
  [[ "${output}" == "AirPods 85%" ]]
}

@test "bluetooth.sh dispatcher - icon subcommand renders when connected" {
  run main icon
  [[ "${output}" == "BT" ]]
}

@test "bluetooth.sh dispatcher - icon is empty with nothing connected" {
  read_bluetooth() { echo ""; }
  run main icon
  [[ -z "${output}" ]]
}

@test "bluetooth.sh dispatcher - unknown subcommand produces no output" {
  run main bogus
  [[ -z "${output}" ]]
}

@test "bluetooth.sh dispatcher - count subcommand renders the device count" {
  read_bluetooth() { echo "AirPods 85%"; echo "Magic Mouse 50%"; }
  run main count
  [[ "${output}" == "2" ]]
}

@test "bluetooth.sh dispatcher - count is 0 with nothing connected" {
  read_bluetooth() { echo ""; }
  run main count
  [[ "${output}" == "0" ]]
}

@test "bluetooth.sh dispatcher - min subcommand renders the lowest battery device" {
  read_bluetooth() { echo "AirPods 85%"; echo "Magic Mouse 50%"; }
  run main min
  [[ "${output}" == "Magic Mouse 50%" ]]
}

@test "bluetooth.sh dispatcher - min is empty with nothing connected" {
  read_bluetooth() { echo ""; }
  run main min
  [[ -z "${output}" ]]
}

@test "bluetooth.sh dispatcher - bluetooth_max_age falls back to 30 for a non-numeric interval" {
  # Arrange
  set_tmux_option "@bluetooth_revamped_interval" 'x[$(touch "${TEST_TMPDIR}/ran")]'

  # Act
  run bluetooth_max_age

  # Assert
  [ "${output}" = "30" ]
}

@test "bluetooth.sh dispatcher - a non-numeric interval never reaches arithmetic" {
  # Arrange
  set_tmux_option "@bluetooth_revamped_interval" 'x[$(touch "${TEST_TMPDIR}/ran")]'

  # Act
  bluetooth_tick

  # Assert
  [ ! -e "${TEST_TMPDIR}/ran" ]
}
