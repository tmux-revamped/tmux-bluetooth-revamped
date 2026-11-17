#!/usr/bin/env bash
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
