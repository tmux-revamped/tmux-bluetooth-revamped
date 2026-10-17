#!/usr/bin/env bash

[[ -n "${_BLUETOOTH_REVAMPED_BLUETOOTH_LOADED:-}" ]] && return 0
_BLUETOOTH_REVAMPED_BLUETOOTH_LOADED=1

_BT_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${_BT_LIB_DIR}/../utils/platform.sh"
# shellcheck source=/dev/null
source "${_BT_LIB_DIR}/../utils/has-command.sh"

bt_parse_macos() {
  printf '%s\n' "${1}" | awk 'function out(b){b=v;if(b=="")b=lr;if(b=="")b=cs;if(n!="")print n (b==""?"":" "b);n="";v="";lr="";cs=""} /Not Connected:/{out();c=0;next} /Connected:/{out();c=1;next} c&&/^[[:space:]]+[^[:space:]].*:[[:space:]]*$/{out();n=$0;sub(/:[[:space:]]*$/,"",n);gsub(/^[[:space:]]+/,"",n);next} c&&/Battery Level:/{x=$0;sub(/.*Battery Level:[[:space:]]*/,"",x);if($0~/(Left|Right) Battery Level:/){if(lr==""||x+0<lr+0)lr=x}else if($0~/Case Battery Level:/)cs=x;else v=x} END{out()}'
}

bt_parse_linux() {
  printf '%s\n' "${1}" | awk 'function out(){if(m!=""&&(np~/bluez/||d~/_dev_/))print m (p==""?"":" "p);m="";p="";np="";d=""} /^[^[:space:]]/{out();d=$0;next} /native-path:/{np=$0;sub(/.*native-path:[[:space:]]*/,"",np)} /model:/{m=$0;sub(/.*model:[[:space:]]*/,"",m)} /percentage:/{p=$0;sub(/.*percentage:[[:space:]]*/,"",p)} END{out()}'
}

_read_bt_macos() { system_profiler SPBluetoothDataType 2>/dev/null; }
_read_bt_linux() { upower --dump 2>/dev/null; }

read_bluetooth() {
  if is_macos; then
    bt_parse_macos "$(_read_bt_macos)"
  elif is_linux && has_command upower; then
    bt_parse_linux "$(_read_bt_linux)"
  fi
}

export -f bt_parse_macos
export -f bt_parse_linux
export -f _read_bt_macos
export -f _read_bt_linux
export -f read_bluetooth
