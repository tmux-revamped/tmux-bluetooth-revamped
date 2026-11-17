#!/usr/bin/env bats
# shellcheck disable=SC2030,SC2031,SC2034,SC2154

# shellcheck source=test/tmux_helpers.bash
source "${BATS_TEST_DIRNAME:-.}/tmux_helpers.bash"

setup() {
  ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
  setup_tmux_server
}

teardown() {
  [[ -z "${HOST:-}" ]] || command tmux -S "${HOST}" kill-server 2>/dev/null || :
  [[ -z "${HOST:-}" ]] || rm -f "${HOST}"
  teardown_tmux_server
}

settled() {
  local delay
  for delay in 0.01 0.02 0.05 0.1 0.2 0.5 1 1 2; do
    "$@" && return 0
    sleep "${delay}"
  done
  "$@"
}

attached() {
  local clients
  clients=$(tmux list-clients -F x 2>/dev/null)
  [[ -n "${clients}" ]]
}

host_shows() {
  local screen
  screen=$(command tmux -S "${HOST}" capture-pane -p -t host)
  [[ "${screen}" == *"$1"* ]]
}

load_plugin() {
  local quoted
  quoted=$(printf '%s' "$1" | sed "s/'/'\\\\''/g")
  tmux run-shell "'${quoted}/bluetooth-revamped.tmux'"
}

key_binding() {
  local table
  table=$(tmux list-keys -T prefix)
  awk -v key="$1" '{ for (i = 1; i < NF; i++) { if ($i == "-T") { if ($(i + 2) == key) { print } break } } }' <<<"${table}"
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

@test "entrypoint - prefix M-h opens the device popup" {
  # Arrange
  local key=M-h

  # Act
  load_plugin "${ROOT}"

  # Assert
  run key_binding "${key}"
  [[ "${output}" == *"display-popup -E"*"bin/bluetooth-revamped' popup"* ]]
}

@test "entrypoint - pressing prefix M-h shows the devices, from a checkout path with a space, a hash and a quote" {
  # Arrange
  local copy="${BATS_TEST_TMPDIR}/it's #1 dir" quoted
  HOST="${TMUX_SOCKET}-host"
  mkdir -p "${copy}" "${BATS_TEST_TMPDIR}/stubs"
  cp -Rf "${ROOT}/bin" "${ROOT}/lib" "${ROOT}/bluetooth-revamped.tmux" "${copy}/"
  cp -f "${ROOT}/test/bin/system_profiler" "${ROOT}/test/bin/blueutil" "${ROOT}/test/bin/uname" "${BATS_TEST_TMPDIR}/stubs/"
  printf 'Bluetooth:\n      Connected:\n          MX Master:\n              Address: AA:BB:CC:00:00:02\n              Battery Level: 50%%\n' >"${BATS_TEST_TMPDIR}/dump"
  quoted=$(printf '%s' "${copy}" | sed -e "s/'/'\\\\''/g" -e 's/#/##/g')
  tmux set-environment -g PATH "${BATS_TEST_TMPDIR}/stubs:${PATH}"
  tmux set-environment -g REVAMPED_TEST_UNAME_S Darwin
  tmux set-environment -g REVAMPED_TEST_BLUETOOTH_DUMP "${BATS_TEST_TMPDIR}/dump"
  tmux run-shell "'${quoted}/bluetooth-revamped.tmux'"
  command tmux -S "${HOST}" -f /dev/null new-session -d -s host -x 120 -y 30 \
    "env -u TMUX TERM=xterm-256color tmux -S '${TMUX_SOCKET}' attach-session -t test"
  settled attached

  # Act
  command tmux -S "${HOST}" send-keys -t host C-b M-h

  # Assert
  settled host_shows "MX Master"
}

@test "entrypoint - the popup key follows its tmux option" {
  # Arrange
  set_option @bluetooth_revamped_popup_key M-y

  # Act
  load_plugin "${ROOT}"

  # Assert
  run key_binding M-y
  [[ "${output}" == *"bluetooth-revamped' popup"* ]]
}

@test "entrypoint - none binds no key" {
  # Arrange
  set_option @bluetooth_revamped_popup_key none

  # Act
  load_plugin "${ROOT}"

  # Assert
  run key_binding M-h
  [[ "${output}" != *"bluetooth-revamped"* ]]
}

@test "entrypoint - a key the person bound stays theirs" {
  # Arrange
  tmux bind-key -T prefix M-h split-window

  # Act
  load_plugin "${ROOT}"

  # Assert
  run key_binding M-h
  [[ "${output}" == *"split-window"* ]]
  [[ "${output}" != *"bluetooth-revamped"* ]]
}

@test "entrypoint - loading twice keeps the popup on its key" {
  # Arrange
  load_plugin "${ROOT}"

  # Act
  load_plugin "${ROOT}"

  # Assert
  run key_binding M-h
  [[ "${output}" == *"bluetooth-revamped' popup"* ]]
}
