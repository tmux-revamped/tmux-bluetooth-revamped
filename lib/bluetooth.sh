#!/bin/sh

[ -n "${BLUETOOTH_REVAMPED_BLUETOOTH_LOADED:-}" ] && return 0
BLUETOOTH_REVAMPED_BLUETOOTH_LOADED=1

# shellcheck source=SCRIPTDIR/state.sh
. "${REVAMPED_LIB:?}/state.sh"
# shellcheck source=SCRIPTDIR/platform.sh
. "${REVAMPED_LIB:?}/platform.sh"
# shellcheck source=SCRIPTDIR/command.sh
. "${REVAMPED_LIB:?}/command.sh"
# shellcheck source=SCRIPTDIR/cache.sh
. "${REVAMPED_LIB:?}/cache.sh"

bluetooth_revamped_parse_macos() {
  awk 'function out(b){b=v;if(b=="")b=lr;if(b=="")b=cs;if(n!="")print n (b==""?"":" "b);n="";v="";lr="";cs=""} /Not Connected:/{out();c=0;next} /Connected:/{out();c=1;next} c&&/^[[:space:]]+[^[:space:]].*:[[:space:]]*$/{out();n=$0;sub(/:[[:space:]]*$/,"",n);gsub(/^[[:space:]]+/,"",n);next} c&&/Battery Level:/{x=$0;sub(/.*Battery Level:[[:space:]]*/,"",x);if($0~/(Left|Right) Battery Level:/){if(lr==""||x+0<lr+0)lr=x}else if($0~/Case Battery Level:/)cs=x;else v=x} END{out()}'
}

bluetooth_revamped_parse_linux() {
  awk 'function out(){if(m!=""&&(np~/bluez/||d~/_dev_/))print m (p==""?"":" "p);m="";p="";np="";d=""} /^[^[:space:]]/{out();d=$0;next} /native-path:/{np=$0;sub(/.*native-path:[[:space:]]*/,"",np)} /model:/{m=$0;sub(/.*model:[[:space:]]*/,"",m)} /percentage:/{p=$0;sub(/.*percentage:[[:space:]]*/,"",p)} END{out()}'
}

bluetooth_revamped_read() {
  if revamped_is_macos; then
    system_profiler SPBluetoothDataType 2>/dev/null | bluetooth_revamped_parse_macos
  elif revamped_is_linux && revamped_has_command upower; then
    upower --dump 2>/dev/null | bluetooth_revamped_parse_linux
  fi
}

bluetooth_revamped_setting() {
  case "$1" in
  interval) bluetooth_revamped_setting_given="${BLUETOOTH_REVAMPED_INTERVAL+1}" bluetooth_revamped_setting_value="${BLUETOOTH_REVAMPED_INTERVAL-}" ;;
  format) bluetooth_revamped_setting_given="${BLUETOOTH_REVAMPED_FORMAT+1}" bluetooth_revamped_setting_value="${BLUETOOTH_REVAMPED_FORMAT-}" ;;
  separator) bluetooth_revamped_setting_given="${BLUETOOTH_REVAMPED_SEPARATOR+1}" bluetooth_revamped_setting_value="${BLUETOOTH_REVAMPED_SEPARATOR-}" ;;
  *) bluetooth_revamped_setting_given="${BLUETOOTH_REVAMPED_ICON+1}" bluetooth_revamped_setting_value="${BLUETOOTH_REVAMPED_ICON-}" ;;
  esac
  if [ -n "${bluetooth_revamped_setting_given}" ]; then
    printf '%s\n' "${bluetooth_revamped_setting_value}"
    return 0
  fi
  revamped_tmux_get "@bluetooth_revamped_$1" "$2"
}

bluetooth_revamped_interval() {
  bluetooth_revamped_interval_value=$(bluetooth_revamped_setting interval "${BLUETOOTH_REVAMPED_DEFAULT_INTERVAL}")
  revamped_cache_is_number "${bluetooth_revamped_interval_value}" || bluetooth_revamped_interval_value="${BLUETOOTH_REVAMPED_DEFAULT_INTERVAL}"
  printf '%s\n' "${bluetooth_revamped_interval_value}"
}

bluetooth_revamped_render_device() {
  if [ -z "$1" ]; then
    printf '\n'
    return 0
  fi
  bluetooth_revamped_render_device_separator=$(bluetooth_revamped_setting separator "${BLUETOOTH_REVAMPED_DEFAULT_SEPARATOR}")
  bluetooth_revamped_render_device_format=$(bluetooth_revamped_setting format "${BLUETOOTH_REVAMPED_DEFAULT_FORMAT}")
  bluetooth_revamped_render_device_out=""
  while IFS= read -r bluetooth_revamped_render_device_line; do
    [ -n "${bluetooth_revamped_render_device_line}" ] || continue
    [ -z "${bluetooth_revamped_render_device_out}" ] || bluetooth_revamped_render_device_out="${bluetooth_revamped_render_device_out}${bluetooth_revamped_render_device_separator}"
    bluetooth_revamped_render_device_out="${bluetooth_revamped_render_device_out}${bluetooth_revamped_render_device_line}"
  done <<EOF
$1
EOF
  # shellcheck disable=SC2059
  printf "${bluetooth_revamped_render_device_format}" "${bluetooth_revamped_render_device_out}"
}

bluetooth_revamped_render_icon() {
  if [ -z "$1" ]; then
    printf '\n'
    return 0
  fi
  bluetooth_revamped_setting icon "${BLUETOOTH_REVAMPED_DEFAULT_ICON}"
}

bluetooth_revamped_render_count() {
  bluetooth_revamped_render_count_n=0
  while IFS= read -r bluetooth_revamped_render_count_line; do
    [ -z "${bluetooth_revamped_render_count_line}" ] || bluetooth_revamped_render_count_n=$((bluetooth_revamped_render_count_n + 1))
  done <<EOF
$1
EOF
  printf '%s\n' "${bluetooth_revamped_render_count_n}"
}

bluetooth_revamped_render_min() {
  bluetooth_revamped_render_min_best=""
  bluetooth_revamped_render_min_level=101
  while IFS= read -r bluetooth_revamped_render_min_line; do
    bluetooth_revamped_render_min_pct="${bluetooth_revamped_render_min_line##* }"
    bluetooth_revamped_render_min_pct="${bluetooth_revamped_render_min_pct%\%}"
    case "${bluetooth_revamped_render_min_line}" in
    *%) revamped_cache_is_number "${bluetooth_revamped_render_min_pct}" || continue ;;
    *) continue ;;
    esac
    [ "${bluetooth_revamped_render_min_pct}" -lt "${bluetooth_revamped_render_min_level}" ] || continue
    bluetooth_revamped_render_min_level="${bluetooth_revamped_render_min_pct}"
    bluetooth_revamped_render_min_best="${bluetooth_revamped_render_min_line}"
  done <<EOF
$1
EOF
  printf '%s\n' "${bluetooth_revamped_render_min_best}"
}

bluetooth_revamped_refresh() {
  bluetooth_revamped_refresh_list=$(bluetooth_revamped_read)
  revamped_cache_set device "${bluetooth_revamped_refresh_list}"
}

bluetooth_revamped_status() {
  bluetooth_revamped_status_age=$(bluetooth_revamped_interval)
  revamped_cache_refresh_if_stale device "${bluetooth_revamped_status_age}" bluetooth_revamped_refresh || :
  bluetooth_revamped_status_list=$(revamped_cache_get device)
  "bluetooth_revamped_render_$1" "${bluetooth_revamped_status_list}"
}

bluetooth_revamped_json() {
  awk '
    function quote(s,    out, i, c) {
      out = ""
      for (i = 1; i <= length(s); i++) {
        c = substr(s, i, 1)
        if (c == "\\") {
          out = out "\\\\"
        } else if (c == "\"") {
          out = out "\\\""
        } else if (c == "\t") {
          out = out "\\t"
        } else {
          out = out c
        }
      }
      return "\"" out "\""
    }
    NF == 0 { next }
    {
      name = $0
      battery = "null"
      if ($NF ~ /^[0-9]+%$/) {
        battery = substr($NF, 1, length($NF) - 1) + 0
        name = substr($0, 1, length($0) - length($NF) - 1)
      }
      rows = rows (rows == "" ? "" : ",") "{\"name\":" quote(name) ",\"battery\":" battery "}"
    }
    END { print "{\"devices\":[" rows "]}" }
  '
}
