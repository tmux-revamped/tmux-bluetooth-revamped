#!/usr/bin/env bats
# shellcheck disable=SC2030,SC2031,SC2034,SC2154

# shellcheck source=test/tmux_helpers.bash
source "${BATS_TEST_DIRNAME:-.}/tmux_helpers.bash"

setup() {
  ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
  setup_tmux_server
}

teardown() {
  teardown_tmux_server
}

load_plugin() {
  local quoted
  quoted=$(printf '%s' "$1" | sed "s/'/'\\\\''/g")
  tmux run-shell "'${quoted}/bluetooth-revamped.tmux'"
}

placeholder_command() {
  sed -n -e 's/##/#/g' -e "s/.*#(\\(.* status $2\\)).*/\\1/p" <<<"$1"
}

@test "entrypoint - every placeholder in status-right becomes a status call" {
  # Arrange
  set_option status-right '#{bluetooth_icon} #{bluetooth} [#{bluetooth_count}] #{bluetooth_min} %H:%M '

  # Act
  load_plugin "${ROOT}"

  # Assert
  local value
  value="$(get_option status-right)"
  [[ "${value}" == "#('${ROOT}/bin/bluetooth-revamped' status icon) #('${ROOT}/bin/bluetooth-revamped' status device) [#('${ROOT}/bin/bluetooth-revamped' status count)] #('${ROOT}/bin/bluetooth-revamped' status min) %H:%M " ]]
}

@test "entrypoint - placeholders in status-left are replaced too" {
  # Arrange
  set_option status-left '#{bluetooth_count} #{bluetooth_count}|'

  # Act
  load_plugin "${ROOT}"

  # Assert
  local value
  value="$(get_option status-left)"
  [[ "${value}" == "#('${ROOT}/bin/bluetooth-revamped' status count) #('${ROOT}/bin/bluetooth-revamped' status count)|" ]]
}

@test "entrypoint - a status line without placeholders is left as it was" {
  # Arrange
  set_option status-right '#[fg=red]#H %H:%M'

  # Act
  load_plugin "${ROOT}"

  # Assert
  local value
  value="$(get_option status-right)"
  [[ "${value}" == '#[fg=red]#H %H:%M' ]]
}

@test "entrypoint - a checkout path with a space, a hash and a quote still runs" {
  # Arrange
  local copy="${BATS_TEST_TMPDIR}/it's #1 dir"
  mkdir -p "${copy}"
  cp -Rf "${ROOT}/bin" "${ROOT}/lib" "${ROOT}/bluetooth-revamped.tmux" "${copy}/"
  set_option status-right '#{bluetooth_count}'
  load_plugin "${copy}"
  local value command
  value="$(get_option status-right)"
  command="$(placeholder_command "${value}" count)"

  # Act
  TMUX="${TMUX_SOCKET},0,0" run sh -c "${command}"

  # Assert
  [[ "${status}" -eq 0 ]]
  [[ "${output}" =~ ^[0-9]+$ ]]
}

@test "entrypoint - git tracks the entry point and the tool as executable" {
  # Arrange
  local entry=bluetooth-revamped.tmux tool=bin/bluetooth-revamped

  # Act
  run git -C "${ROOT}" ls-files --stage -- "${entry}" "${tool}"

  # Assert
  [[ "${lines[0]}" == 100755\ * ]]
  [[ "${lines[1]}" == 100755\ * ]]
}
