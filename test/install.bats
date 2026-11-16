#!/usr/bin/env bats
# shellcheck disable=SC2016,SC2030,SC2031,SC2034

# shellcheck source=test/helpers.bash
source "${BATS_TEST_DIRNAME:-.}/helpers.bash"

setup() {
  harness_setup
  ROOT="$(cd "${REVAMPED_TESTS_DIR}/.." && pwd)"
}

complete_words() {
  # shellcheck source=completions/bluetooth-revamped.bash
  source "${ROOT}/completions/bluetooth-revamped.bash"
  COMP_WORDS=("$@")
  COMP_CWORD=$(($# - 1))
  _bluetooth_revamped
  printf '%s\n' "${COMPREPLY[@]}"
}

@test "install - make install puts a working tool, its man page and completions under PREFIX" {
  # Arrange
  local prefix="${BATS_TEST_TMPDIR}/prefix with space"

  # Act
  make -s -C "${ROOT}" install PREFIX="${prefix}"

  # Assert
  run "${prefix}/bin/bluetooth-revamped" version
  [[ "${status}" -eq 0 ]]
  [[ "${lines[0]}" == bluetooth-revamped\ * ]]
  [[ -f "${prefix}/share/man/man1/bluetooth-revamped.1" ]]
  [[ -f "${prefix}/share/bash-completion/completions/bluetooth-revamped" ]]
  [[ -f "${prefix}/share/zsh/site-functions/_bluetooth-revamped" ]]
  [[ -f "${prefix}/share/fish/vendor_completions.d/bluetooth-revamped.fish" ]]
}

@test "install - a second install replaces the first" {
  # Arrange
  local prefix="${BATS_TEST_TMPDIR}/prefix"
  make -s -C "${ROOT}" install PREFIX="${prefix}"
  printf 'stale\n' >"${prefix}/share/bluetooth-revamped/lib/stale.sh"

  # Act
  make -s -C "${ROOT}" install PREFIX="${prefix}"

  # Assert
  [[ ! -e "${prefix}/share/bluetooth-revamped/lib/stale.sh" ]]
  [[ -x "${prefix}/bin/bluetooth-revamped" ]]
}

@test "install - bash completes the commands" {
  # Arrange
  local word='do'

  # Act
  run complete_words bluetooth-revamped "${word}"

  # Assert
  [[ "${output}" == "doctor" ]]
}

@test "install - bash completes the themes after --theme" {
  # Arrange
  local word=no

  # Act
  run complete_words bluetooth-revamped --theme "${word}"

  # Assert
  [[ "${output}" == "nord" ]]
}

@test "install - bash completes the placeholders after status" {
  # Arrange
  local word=c

  # Act
  run complete_words bluetooth-revamped status "${word}"

  # Assert
  [[ "${output}" == "count" ]]
}

@test "install - bash completes no word after an option that takes text" {
  # Arrange
  local word=d

  # Act
  run complete_words bluetooth-revamped --icon "${word}"

  # Assert
  [[ -z "${output}" ]]
}

@test "install - bash completes the power states" {
  # Arrange
  local word=t

  # Act
  run complete_words bluetooth-revamped power "${word}"

  # Assert
  [[ "${output}" == "toggle" ]]
}

@test "install - bash completes 0 and 1 after a switch" {
  # Arrange
  local word=""

  # Act
  run complete_words bluetooth-revamped --icons "${word}"

  # Assert
  [[ "${output}" == $'0\n1' ]]
}
