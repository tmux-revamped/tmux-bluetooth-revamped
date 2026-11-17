#!/usr/bin/env bash
# shellcheck disable=SC2016,SC2030,SC2031,SC2034

# shellcheck source=test/helpers.bash
source "${BATS_TEST_DIRNAME:-.}/helpers.bash"

setup() {
  harness_setup
  unset BLUETOOTH_REVAMPED_INTERVAL BLUETOOTH_REVAMPED_FORMAT BLUETOOTH_REVAMPED_SEPARATOR BLUETOOTH_REVAMPED_ICON
  export REVAMPED_TEST_NOW=1000000 REVAMPED_TEST_BLUETOOTH_LOG="${BATS_TEST_TMPDIR}/readers.log"
  DUMP="${BATS_TEST_TMPDIR}/dump"
}

dump() {
  printf '%b' "$1" >"${DUMP}"
  export REVAMPED_TEST_BLUETOOTH_DUMP="${DUMP}"
}

parse() {
  dump "$2"
  lib_run bluetooth "bluetooth_revamped_parse_$1 <\"${DUMP}\""
}

option() {
  printf '%s' "$2" >"${REVAMPED_TEST_TMUX_DIR}/$(printf '%s' "g.-.$1" | tr -c 'A-Za-z0-9_.-' '_')"
}

stored() {
  local key
  key=$(printf '%s' "g.-.$1" | tr -c 'A-Za-z0-9_.-' '_')
  STORED=$(<"${REVAMPED_TEST_TMUX_DIR}/${key}")
}

macos_dump() {
  dump 'Bluetooth:\n      Bluetooth Controller:\n          Address: 00:00:00:00:00:00\n          State: On\n      Connected:\n          AirPods Pro:\n              Address: AA:BB:CC:00:00:01\n              Left Battery Level: 90%\n              Right Battery Level: 15%\n              Minor Type: Headphones\n          MX Master 3S:\n              Address: AA:BB:CC:00:00:02\n              Battery Level: 50%\n              Minor Type: Mouse\n      Not Connected:\n          Magic Keyboard:\n              Address: AA:BB:CC:00:00:03\n              Minor Type: Keyboard\n'
}

linux_dumps() {
  export REVAMPED_TEST_BLUETOOTH_PAIRED="${BATS_TEST_TMPDIR}/paired" REVAMPED_TEST_BLUETOOTH_CONNECTED="${BATS_TEST_TMPDIR}/connected"
  printf 'Device AA:BB:CC:00:00:01 WH-1000XM4\nDevice AA:BB:CC:00:00:02 MX Master 3S\nDevice AA:BB:CC:00:00:03 Pad\n' >"${REVAMPED_TEST_BLUETOOTH_PAIRED}"
  printf 'Device AA:BB:CC:00:00:01 WH-1000XM4\n' >"${REVAMPED_TEST_BLUETOOTH_CONNECTED}"
  dump 'Device: /org/freedesktop/UPower/devices/headset_dev_AA_BB_CC_00_00_01\n  native-path:          /org/bluez/hci0/dev_AA_BB_CC_00_00_01\n  model:                WH-1000XM4\n  headset\n    percentage:          80%\nDevice: /org/freedesktop/UPower/devices/battery_BAT0\n  native-path:          BAT0\n  battery\n    percentage:          64%\n'
}
