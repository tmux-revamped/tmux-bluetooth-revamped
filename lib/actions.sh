#!/bin/sh
# shellcheck disable=SC2034

[ -n "${BLUETOOTH_REVAMPED_ACTIONS_LOADED:-}" ] && return 0
BLUETOOTH_REVAMPED_ACTIONS_LOADED=1

# shellcheck source=SCRIPTDIR/bluetooth.sh
. "${REVAMPED_LIB:?}/bluetooth.sh"

bluetooth_revamped_popup_key() {
  bluetooth_revamped_setting popup_key "${BLUETOOTH_REVAMPED_DEFAULT_POPUP_KEY}"
}

bluetooth_revamped_tool() {
  if revamped_is_macos; then
    printf 'blueutil\n'
  else
    printf 'bluetoothctl\n'
  fi
}

bluetooth_revamped_remedy() {
  if revamped_is_macos; then
    printf 'brew install blueutil\n'
  else
    printf 'apt install bluez\n'
  fi
}

bluetooth_revamped_need_tool() {
  BLUETOOTH_REVAMPED_TOOL=$(bluetooth_revamped_tool)
  BLUETOOTH_REVAMPED_PROBLEM=""
  revamped_has_command "${BLUETOOTH_REVAMPED_TOOL}" && return 0
  bluetooth_revamped_need_tool_remedy=$(bluetooth_revamped_remedy)
  BLUETOOTH_REVAMPED_PROBLEM="$1 needs ${BLUETOOTH_REVAMPED_TOOL}. install it with: ${bluetooth_revamped_need_tool_remedy}"
}

bluetooth_revamped_find() {
  printf '%s\n' "${BLUETOOTH_REVAMPED_RECORDS}" | BLUETOOTH_REVAMPED_WANT="$1" awk -F '\t' '
    BEGIN { want = ENVIRON["BLUETOOTH_REVAMPED_WANT"] }
    NF >= 5 && (tolower($2) == tolower(want) || $5 == want) { print $1 "\t" $2 "\t" $5; exit }
  '
}

bluetooth_revamped_names() {
  printf '%s\n' "${BLUETOOTH_REVAMPED_RECORDS}" | awk -F '\t' -v state="$1" 'NF >= 5 && $1 == state { print $5 }'
}

bluetooth_revamped_run_tool() {
  if revamped_is_macos; then
    blueutil "--$1" "$2" >/dev/null 2>&1
  else
    bluetoothctl "$1" "$2" >/dev/null 2>&1
  fi
}

bluetooth_revamped_action() {
  bluetooth_revamped_need_tool "$1"
  [ -z "${BLUETOOTH_REVAMPED_PROBLEM}" ] || return 0
  bluetooth_revamped_collect
  bluetooth_revamped_action_match=$(bluetooth_revamped_find "$2")
  if [ -z "${bluetooth_revamped_action_match}" ]; then
    BLUETOOTH_REVAMPED_PROBLEM="no paired device is named or addressed '$2'"
    return 0
  fi
  bluetooth_revamped_action_address=$(printf '%s\n' "${bluetooth_revamped_action_match}" | cut -f 2)
  bluetooth_revamped_action_name=$(printf '%s\n' "${bluetooth_revamped_action_match}" | cut -f 3)
  if ! bluetooth_revamped_run_tool "$1" "${bluetooth_revamped_action_address}"; then
    BLUETOOTH_REVAMPED_PROBLEM="${BLUETOOTH_REVAMPED_TOOL} could not $1 ${bluetooth_revamped_action_name}"
    return 0
  fi
  bluetooth_revamped_refresh
  BLUETOOTH_REVAMPED_DONE="${bluetooth_revamped_action_name} is $1ed."
}

bluetooth_revamped_power_state() {
  if revamped_is_macos; then
    bluetooth_revamped_power_state_raw=$(blueutil --power 2>/dev/null) || bluetooth_revamped_power_state_raw=""
  else
    bluetooth_revamped_power_state_raw=$(bluetoothctl show 2>/dev/null) || bluetooth_revamped_power_state_raw=""
  fi
  case "${bluetooth_revamped_power_state_raw}" in
  1 | *"Powered: yes"*) printf 'on\n' ;;
  *) printf 'off\n' ;;
  esac
}

bluetooth_revamped_power() {
  bluetooth_revamped_need_tool power
  [ -z "${BLUETOOTH_REVAMPED_PROBLEM}" ] || return 0
  bluetooth_revamped_power_want="$1"
  if [ "$1" = toggle ]; then
    bluetooth_revamped_power_now=$(bluetooth_revamped_power_state)
    bluetooth_revamped_power_want=on
    [ "${bluetooth_revamped_power_now}" = off ] || bluetooth_revamped_power_want=off
  fi
  if ! bluetooth_revamped_switch "${bluetooth_revamped_power_want}"; then
    BLUETOOTH_REVAMPED_PROBLEM="${BLUETOOTH_REVAMPED_TOOL} could not turn Bluetooth ${bluetooth_revamped_power_want}"
    return 0
  fi
  bluetooth_revamped_refresh
  BLUETOOTH_REVAMPED_DONE="Bluetooth is ${bluetooth_revamped_power_want}."
}

bluetooth_revamped_switch() {
  if revamped_is_macos; then
    case "$1" in
    on) blueutil --power 1 >/dev/null 2>&1 ;;
    *) blueutil --power 0 >/dev/null 2>&1 ;;
    esac
    return
  fi
  bluetoothctl power "$1" >/dev/null 2>&1
}
