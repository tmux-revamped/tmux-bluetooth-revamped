#!/usr/bin/env bats
# shellcheck disable=SC2016,SC2030,SC2031

load "${BATS_TEST_DIRNAME:-.}/tmux_helpers.bash"

@test "tmux_helpers - the test server starts without the user's tmux.conf" {
  # Arrange
  local log="${BATS_TEST_TMPDIR:?}/tmux-args"
  command() { printf '%s\n' "$*" >"${log}"; }

  # Act
  setup_tmux_server

  # Assert
  actual="$(cat "${log}")"
  [[ "${actual}" == *"-f /dev/null new-session"* ]]
}
