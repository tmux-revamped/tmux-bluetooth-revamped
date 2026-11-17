#!/bin/sh

bluetooth_revamped_dir=$(cd "$(dirname "$0")" && pwd)
bluetooth_revamped_quoted=$(printf '%s\n' "${bluetooth_revamped_dir}/bin/bluetooth-revamped" | sed -e "s/'/'\\\\''/g" -e 's/#/##/g')

bluetooth_revamped_interpolate() {
  BLUETOOTH_REVAMPED_COMMAND="'${bluetooth_revamped_quoted}' status" awk '
    BEGIN {
      command = ENVIRON["BLUETOOTH_REVAMPED_COMMAND"]
      split("bluetooth bluetooth_icon bluetooth_count bluetooth_min", names, " ")
      split("device icon count min", kinds, " ")
    }
    {
      line = $0
      for (i = 1; i <= 4; i++) {
        holder = "#{" names[i] "}"
        done = ""
        while ((at = index(line, holder)) > 0) {
          done = done substr(line, 1, at - 1) "#(" command " " kinds[i] ")"
          line = substr(line, at + length(holder))
        }
        line = done line
      }
      print line
    }
  '
}

for bluetooth_revamped_option in status-left status-right; do
  bluetooth_revamped_current=$(tmux show-option -gqv "${bluetooth_revamped_option}")
  bluetooth_revamped_new=$(printf '%s\n' "${bluetooth_revamped_current}" | bluetooth_revamped_interpolate)
  tmux set-option -gq "${bluetooth_revamped_option}" "${bluetooth_revamped_new}"
done

bluetooth_revamped_key=$(tmux show-option -gqv @bluetooth_revamped_popup_key)
[ -n "${bluetooth_revamped_key}" ] || bluetooth_revamped_key=M-h
bluetooth_revamped_bind() {
  bluetooth_revamped_bind_tool=$(printf '%s\n' "${bluetooth_revamped_dir}/bin/bluetooth-revamped" | sed -e "s/'/'\\\\''/g" -e "s/#/'\"\$(printf '%b' '\\\\0043')\"'/g")
  tmux bind-key -T prefix "${bluetooth_revamped_key}" display-popup -E -w 80% -h 80% "'${bluetooth_revamped_bind_tool}' popup"
}

bluetooth_revamped_binding() {
  tmux list-keys -T prefix 2>/dev/null | awk -v key="$1" '{ for (i = 1; i < NF; i++) { if ($i == "-T") { if ($(i + 2) == key) { print } break } } }'
}

if [ "${bluetooth_revamped_key}" != none ]; then
  bluetooth_revamped_bound=$(bluetooth_revamped_binding "${bluetooth_revamped_key}")
  case "${bluetooth_revamped_bound}" in
  "" | *bluetooth-revamped*) bluetooth_revamped_bind ;;
  *) : ;;
  esac
fi
