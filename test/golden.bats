#!/usr/bin/env bats
# shellcheck disable=SC2030,SC2031

# shellcheck source=test/helpers.bash
source "${BATS_TEST_DIRNAME:-.}/helpers.bash"

setup() {
  harness_setup
  unset KODOUGU_THEME KODOUGU_ACCENT NO_COLOR BLUETOOTH_REVAMPED_THEME BLUETOOTH_REVAMPED_ACCENT
  export REVAMPED_TEST_TMUX_VERSION=3.8 REVAMPED_TEST_UNAME_S=Darwin REVAMPED_TEST_NOW=1000000
  export REVAMPED_TEST_BLUETOOTH_DUMP="${BATS_TEST_TMPDIR}/dump"
  printf 'Bluetooth:\n    Connected:\n        AirPods Pro:\n            Left Battery Level: 90%%\n            Right Battery Level: 85%%\n        Magic Keyboard:\n            Address: 00-22\n        MX Master:\n            Battery Level: 50%%\n' >"${REVAMPED_TEST_BLUETOOTH_DUMP}"
}

stored_reading() {
  # shellcheck disable=SC2086
  ${REVAMPED_TEST_SHELL:-sh} "${REVAMPED_TESTS_DIR}/../bin/bluetooth-revamped" refresh >/dev/null
}

transcript() {
  local flow="$1"
  shift
  # shellcheck disable=SC2086
  run ${REVAMPED_TEST_SHELL:-sh} "${REVAMPED_TESTS_DIR}/../bin/bluetooth-revamped" "$@"
  TRANSCRIPT="$(printf '$ bluetooth-revamped%s\n%s\nexit %s\n' "${*:+ $*}" "${output}" "${status}" | steady)"
  local system
  system="$(/usr/bin/uname -s)"
  case "${system}" in
  Darwin) system=darwin ;;
  *) system=linux ;;
  esac
  GOLDEN="${REVAMPED_TESTS_DIR}/golden/${flow}.${system}.txt"
  if [[ -n "${REVAMPED_TEST_RECORD:-}" ]]; then
    printf '%s\n' "${TRANSCRIPT}" >"${GOLDEN}"
  fi
}

steady() {
  sed -E \
    -e 's#/[^ ,]+#<path>#g' \
    -e 's/(gnu|bsd|uutils|busybox|mawk)( [0-9][0-9.]*)?$/<flavor>/' \
    -e 's/^bluetooth-revamped [0-9]+\.[0-9]+\.[0-9]+$/bluetooth-revamped <version>/'
}

@test "golden - help" {
  # Arrange
  local flow=help

  # Act
  transcript "${flow}" help

  # Assert
  diff -u "${GOLDEN}" <(printf '%s\n' "${TRANSCRIPT}")
}

@test "golden - version" {
  # Arrange
  local flow=version

  # Act
  transcript "${flow}" version

  # Assert
  diff -u "${GOLDEN}" <(printf '%s\n' "${TRANSCRIPT}")
}

@test "golden - doctor" {
  # Arrange
  local flow=doctor
  unset REVAMPED_TEST_UNAME_S
  harness_hide osascript notify-send

  # Act
  transcript "${flow}" doctor

  # Assert
  diff -u "${GOLDEN}" <(printf '%s\n' "${TRANSCRIPT}")
}

@test "golden - an unknown command" {
  # Arrange
  local flow=unknown-command

  # Act
  transcript "${flow}" frobnicate

  # Assert
  diff -u "${GOLDEN}" <(printf '%s\n' "${TRANSCRIPT}")
}

@test "golden - an unknown option" {
  # Arrange
  local flow=unknown-option

  # Act
  transcript "${flow}" --frobnicate

  # Assert
  diff -u "${GOLDEN}" <(printf '%s\n' "${TRANSCRIPT}")
}

@test "golden - a bare run without a terminal" {
  # Arrange
  local flow=no-terminal

  # Act
  transcript "${flow}"

  # Assert
  diff -u "${GOLDEN}" <(printf '%s\n' "${TRANSCRIPT}")
}

@test "golden - list" {
  # Arrange
  local flow=list

  # Act
  transcript "${flow}" list

  # Assert
  diff -u "${GOLDEN}" <(printf '%s\n' "${TRANSCRIPT}")
}

@test "golden - list as JSON" {
  # Arrange
  local flow=list-json

  # Act
  transcript "${flow}" list --json

  # Assert
  diff -u "${GOLDEN}" <(printf '%s\n' "${TRANSCRIPT}")
}

@test "golden - refresh" {
  # Arrange
  local flow=refresh

  # Act
  transcript "${flow}" refresh

  # Assert
  diff -u "${GOLDEN}" <(printf '%s\n' "${TRANSCRIPT}")
}

@test "golden - every placeholder with a stored reading" {
  # Arrange
  local flow=status
  stored_reading

  # Act
  transcript "${flow}" --separator ' | ' --format '[%s]' status device

  # Assert
  diff -u "${GOLDEN}" <(printf '%s\n' "${TRANSCRIPT}")
}
