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
# shellcheck source=SCRIPTDIR/notify.sh
. "${REVAMPED_LIB:?}/notify.sh"

bluetooth_revamped_parse_macos() {
  awk 'function out(b){b=v;if(b=="")b=lr;if(b=="")b=cs;if(n!="")print n (b==""?"":" "b);n="";v="";lr="";cs=""} /Not Connected:/{out();c=0;next} /Connected:/{out();c=1;next} c&&/^[[:space:]]+[^[:space:]].*:[[:space:]]*$/{out();n=$0;sub(/:[[:space:]]*$/,"",n);gsub(/^[[:space:]]+/,"",n);next} c&&/Battery Level:/{x=$0;sub(/.*Battery Level:[[:space:]]*/,"",x);if($0~/(Left|Right) Battery Level:/){if(lr==""||x+0<lr+0)lr=x}else if($0~/Case Battery Level:/)cs=x;else v=x} END{out()}'
}

bluetooth_revamped_parse_linux() {
  awk 'function out(){if(m!=""&&(np~/bluez/||d~/_dev_/))print m (p==""?"":" "p);m="";p="";np="";d=""} /^[^[:space:]]/{out();d=$0;next} /native-path:/{np=$0;sub(/.*native-path:[[:space:]]*/,"",np)} /model:/{m=$0;sub(/.*model:[[:space:]]*/,"",m)} /percentage:/{p=$0;sub(/.*percentage:[[:space:]]*/,"",p)} END{out()}'
}

bluetooth_revamped_raw() {
  if revamped_is_macos; then
    system_profiler SPBluetoothDataType 2>/dev/null
  elif revamped_is_linux && revamped_has_command upower; then
    upower --dump 2>/dev/null
  fi
}

bluetooth_revamped_parse() {
  if revamped_is_macos; then
    bluetooth_revamped_parse_macos
  else
    bluetooth_revamped_parse_linux
  fi
}

bluetooth_revamped_read() {
  bluetooth_revamped_raw | bluetooth_revamped_parse
}

bluetooth_revamped_records_macos() {
  awk '
    function kind(t) {
      t = tolower(t)
      if (t ~ /head(phones|set)|earbud/) { return "headphones" }
      if (t ~ /mouse|trackpad/) { return "mouse" }
      if (t ~ /keyboard/) { return "keyboard" }
      if (t ~ /game|joystick/) { return "gamepad" }
      if (t ~ /speaker/) { return "speaker" }
      if (t ~ /phone/) { return "phone" }
      if (t ~ /watch/) { return "watch" }
      return "other"
    }
    function value(line) { sub(/^[^:]*:[[:space:]]*/, "", line); return line }
    function out(level) {
      level = v
      if (level == "") { level = lr }
      if (level == "") { level = cs }
      sub(/%$/, "", level)
      if (n != "") { printf "%s\t%s\t%s\t%s\t%s\n", st, a, kind(mt), level, n }
      n = ""; a = ""; mt = ""; v = ""; lr = ""; cs = ""
    }
    /^[[:space:]]*Not Connected:[[:space:]]*$/ { out(); st = "paired"; next }
    /^[[:space:]]*Connected:[[:space:]]*$/ { out(); st = "connected"; next }
    st == "" { next }
    /^[[:space:]]+[^[:space:]].*:[[:space:]]*$/ { out(); n = $0; sub(/:[[:space:]]*$/, "", n); gsub(/^[[:space:]]+/, "", n); next }
    /^[[:space:]]*Address:/ { a = value($0) }
    /Minor Type:/ { mt = value($0) }
    /Battery Level:/ {
      x = value($0)
      if ($0 ~ /(Left|Right) Battery Level:/) { if (lr == "" || x + 0 < lr + 0) { lr = x } }
      else if ($0 ~ /Case Battery Level:/) { cs = x }
      else { v = x }
    }
    END { out() }
  '
}

bluetooth_revamped_records_linux() {
  awk '
    function kind(t) {
      if (t ~ /head(set|phones)/) { return "headphones" }
      if (t ~ /mouse|touchpad/) { return "mouse" }
      if (t ~ /keyboard/) { return "keyboard" }
      if (t ~ /gaming/) { return "gamepad" }
      if (t ~ /speaker/) { return "speaker" }
      if (t ~ /phone/) { return "phone" }
      return "other"
    }
    /^== connected$/ { part = 1; next }
    /^== upower$/ { part = 2; next }
    part == 0 && $1 == "Device" && $2 ~ /:/ { order[++count] = $2; name = $0; sub(/^Device [^ ]+ /, "", name); names[$2] = name; next }
    part == 1 && $1 == "Device" { connected[$2] = 1; next }
    part == 2 && /^[^[:space:]]/ { address = ""; next }
    part == 2 && /native-path:/ && /dev_/ { address = $0; sub(/.*dev_/, "", address); gsub(/_/, ":", address); next }
    part == 2 && address != "" && /^  [a-z-]+[[:space:]]*$/ { kinds[address] = $1; next }
    part == 2 && address != "" && /percentage:/ { level = $2; sub(/%$/, "", level); levels[address] = level + 0 }
    END {
      for (i = 1; i <= count; i++) {
        a = order[i]
        printf "%s\t%s\t%s\t%s\t%s\n", (a in connected) ? "connected" : "paired", a, kind(kinds[a]), levels[a], names[a]
      }
    }
  '
}

bluetooth_revamped_records() {
  if revamped_is_macos; then
    printf '%s\n' "$1" | bluetooth_revamped_records_macos
    return 0
  fi
  revamped_has_command bluetoothctl || return 0
  bluetooth_revamped_records_paired=$(bluetoothctl devices Paired 2>/dev/null) || bluetooth_revamped_records_paired=""
  bluetooth_revamped_records_connected=$(bluetoothctl devices Connected 2>/dev/null) || bluetooth_revamped_records_connected=""
  printf '%s\n== connected\n%s\n== upower\n%s\n' "${bluetooth_revamped_records_paired}" "${bluetooth_revamped_records_connected}" "$1" | bluetooth_revamped_records_linux
}

bluetooth_revamped_setting() {
  case "$1" in
  interval) bluetooth_revamped_setting_given="${BLUETOOTH_REVAMPED_INTERVAL+1}" bluetooth_revamped_setting_value="${BLUETOOTH_REVAMPED_INTERVAL-}" ;;
  format) bluetooth_revamped_setting_given="${BLUETOOTH_REVAMPED_FORMAT+1}" bluetooth_revamped_setting_value="${BLUETOOTH_REVAMPED_FORMAT-}" ;;
  separator) bluetooth_revamped_setting_given="${BLUETOOTH_REVAMPED_SEPARATOR+1}" bluetooth_revamped_setting_value="${BLUETOOTH_REVAMPED_SEPARATOR-}" ;;
  icon) bluetooth_revamped_setting_given="${BLUETOOTH_REVAMPED_ICON+1}" bluetooth_revamped_setting_value="${BLUETOOTH_REVAMPED_ICON-}" ;;
  notify) bluetooth_revamped_setting_given="${BLUETOOTH_REVAMPED_NOTIFY+1}" bluetooth_revamped_setting_value="${BLUETOOTH_REVAMPED_NOTIFY-}" ;;
  low) bluetooth_revamped_setting_given="${BLUETOOTH_REVAMPED_LOW+1}" bluetooth_revamped_setting_value="${BLUETOOTH_REVAMPED_LOW-}" ;;
  *) bluetooth_revamped_setting_given="${BLUETOOTH_REVAMPED_POPUP_KEY+1}" bluetooth_revamped_setting_value="${BLUETOOTH_REVAMPED_POPUP_KEY-}" ;;
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

bluetooth_revamped_render_read() {
  bluetooth_revamped_render_read_raw=$(tmux display-message -p '#{@bluetooth_revamped_separator}	#{@bluetooth_revamped_format}	#{@bluetooth_revamped_icons}	#{@bluetooth_revamped_details}' 2>/dev/null) || bluetooth_revamped_render_read_raw="			"
  bluetooth_revamped_render_read_rest="${bluetooth_revamped_render_read_raw}"
  BLUETOOTH_REVAMPED_RENDER_SEPARATOR="${bluetooth_revamped_render_read_rest%%	*}"
  bluetooth_revamped_render_read_rest="${bluetooth_revamped_render_read_rest#*	}"
  BLUETOOTH_REVAMPED_RENDER_FORMAT="${bluetooth_revamped_render_read_rest%%	*}"
  bluetooth_revamped_render_read_rest="${bluetooth_revamped_render_read_rest#*	}"
  BLUETOOTH_REVAMPED_RENDER_ICONS="${bluetooth_revamped_render_read_rest%%	*}"
  BLUETOOTH_REVAMPED_RENDER_DETAILS="${bluetooth_revamped_render_read_rest#*	}"
  [ -n "${BLUETOOTH_REVAMPED_RENDER_SEPARATOR}" ] || BLUETOOTH_REVAMPED_RENDER_SEPARATOR="${BLUETOOTH_REVAMPED_DEFAULT_SEPARATOR}"
  [ -n "${BLUETOOTH_REVAMPED_RENDER_FORMAT}" ] || BLUETOOTH_REVAMPED_RENDER_FORMAT="${BLUETOOTH_REVAMPED_DEFAULT_FORMAT}"
  [ -z "${BLUETOOTH_REVAMPED_SEPARATOR+1}" ] || BLUETOOTH_REVAMPED_RENDER_SEPARATOR="${BLUETOOTH_REVAMPED_SEPARATOR}"
  [ -z "${BLUETOOTH_REVAMPED_FORMAT+1}" ] || BLUETOOTH_REVAMPED_RENDER_FORMAT="${BLUETOOTH_REVAMPED_FORMAT}"
  [ -z "${BLUETOOTH_REVAMPED_ICONS+1}" ] || BLUETOOTH_REVAMPED_RENDER_ICONS="${BLUETOOTH_REVAMPED_ICONS}"
}

bluetooth_revamped_render_device() {
  if [ -z "$1" ]; then
    printf '\n'
    return 0
  fi
  bluetooth_revamped_render_read
  bluetooth_revamped_render_device_list="$1"
  [ "${BLUETOOTH_REVAMPED_RENDER_ICONS}" != 1 ] || bluetooth_revamped_render_device_list=$(bluetooth_revamped_iconify "$1" "${BLUETOOTH_REVAMPED_RENDER_DETAILS}")
  bluetooth_revamped_render_device_out=""
  while IFS= read -r bluetooth_revamped_render_device_line; do
    [ -n "${bluetooth_revamped_render_device_line}" ] || continue
    [ -z "${bluetooth_revamped_render_device_out}" ] || bluetooth_revamped_render_device_out="${bluetooth_revamped_render_device_out}${BLUETOOTH_REVAMPED_RENDER_SEPARATOR}"
    bluetooth_revamped_render_device_out="${bluetooth_revamped_render_device_out}${bluetooth_revamped_render_device_line}"
  done <<EOF
${bluetooth_revamped_render_device_list}
EOF
  # shellcheck disable=SC2059
  printf "${BLUETOOTH_REVAMPED_RENDER_FORMAT}" "${bluetooth_revamped_render_device_out}"
}

bluetooth_revamped_iconify() {
  printf '%s\n' "$1" | BLUETOOTH_REVAMPED_ICON_RECORDS="$2" awk '
    BEGIN {
      glyph["headphones"] = "\363\260\213\213"
      glyph["mouse"] = "\363\260\215\275"
      glyph["keyboard"] = "\363\260\214\214"
      glyph["gamepad"] = "\363\260\212\227"
      glyph["speaker"] = "\363\260\223\203"
      glyph["phone"] = "\363\260\217\262"
      glyph["watch"] = "\363\260\226\211"
      glyph["other"] = "\363\260\202\257"
      count = split(ENVIRON["BLUETOOTH_REVAMPED_ICON_RECORDS"], records, "\n")
      for (i = 1; i <= count; i++) {
        if (split(records[i], field, "\t") >= 5) { kinds[field[5]] = field[3] }
      }
    }
    NF == 0 { print; next }
    {
      best = ""
      for (name in kinds) {
        if (($0 == name || index($0, name " ") == 1) && length(name) > length(best)) { best = name }
      }
      kind = (best == "") ? "other" : kinds[best]
      print glyph[kind] " " $0
    }
  '
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

bluetooth_revamped_collect() {
  bluetooth_revamped_collect_raw=$(bluetooth_revamped_raw) || bluetooth_revamped_collect_raw=""
  BLUETOOTH_REVAMPED_LIST=$(printf '%s\n' "${bluetooth_revamped_collect_raw}" | bluetooth_revamped_parse)
  BLUETOOTH_REVAMPED_RECORDS=$(bluetooth_revamped_records "${bluetooth_revamped_collect_raw}")
}

bluetooth_revamped_refresh() {
  bluetooth_revamped_collect
  BLUETOOTH_REVAMPED_STORED=1
  revamped_cache_set device "${BLUETOOTH_REVAMPED_LIST}" || BLUETOOTH_REVAMPED_STORED=0
  [ "${BLUETOOTH_REVAMPED_STORED}" = 1 ] || return 0
  revamped_tmux_set @bluetooth_revamped_details "${BLUETOOTH_REVAMPED_RECORDS}" || :
  bluetooth_revamped_alert
}

bluetooth_revamped_low() {
  bluetooth_revamped_low_value=$(bluetooth_revamped_setting low "${BLUETOOTH_REVAMPED_DEFAULT_LOW}")
  revamped_cache_is_number "${bluetooth_revamped_low_value}" || bluetooth_revamped_low_value="${BLUETOOTH_REVAMPED_DEFAULT_LOW}"
  printf '%s\n' "${bluetooth_revamped_low_value}"
}

bluetooth_revamped_alert() {
  bluetooth_revamped_alert_on=$(bluetooth_revamped_setting notify 0)
  [ "${bluetooth_revamped_alert_on}" = 1 ] || return 0
  bluetooth_revamped_alert_level=$(bluetooth_revamped_low)
  bluetooth_revamped_alert_seen=$(revamped_tmux_get @bluetooth_revamped_notified)
  bluetooth_revamped_alert_plan=$(printf '%s\n' "${BLUETOOTH_REVAMPED_RECORDS}" | BLUETOOTH_REVAMPED_SEEN="${bluetooth_revamped_alert_seen}" awk -F '\t' -v low="${bluetooth_revamped_alert_level}" '
    BEGIN { split(ENVIRON["BLUETOOTH_REVAMPED_SEEN"], seen_list, "\n"); for (i in seen_list) { seen[seen_list[i]] = 1 } }
    $1 == "connected" && $4 != "" && $4 + 0 < low + 0 { print "keep\t" $5; if (!($5 in seen)) { print "send\t" $5 "\t" $4 } }
  ')
  bluetooth_revamped_alert_keep=""
  while IFS='	' read -r bluetooth_revamped_alert_verb bluetooth_revamped_alert_name bluetooth_revamped_alert_pct; do
    case "${bluetooth_revamped_alert_verb}" in
    keep) bluetooth_revamped_alert_keep="${bluetooth_revamped_alert_keep}${bluetooth_revamped_alert_name}
" ;;
    send) revamped_notify_send "Bluetooth battery low" "${bluetooth_revamped_alert_name} is at ${bluetooth_revamped_alert_pct}%." ;;
    *) continue ;;
    esac
  done <<EOF
${bluetooth_revamped_alert_plan}
EOF
  revamped_tmux_set @bluetooth_revamped_notified "${bluetooth_revamped_alert_keep}"
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
