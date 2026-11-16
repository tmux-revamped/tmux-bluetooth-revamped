#!/bin/sh
set -eu

: "${SCREENS_REPO:?}"
demo=/Users/Shared/demo
rm -rf "${demo}"
mkdir -p "${demo}/home" "${demo}/bin"
printf 'connected\tAA:BB:CC:00:00:01\tHeadphones\t85\tAirPods Pro\nconnected\tAA:BB:CC:00:00:02\tMouse\t50\tMX Master 3S\npaired\tAA:BB:CC:00:00:03\tKeyboard\t\tMagic Keyboard\n' >"${demo}/devices.tsv"
printf '1\n' >"${demo}/power"
cat >"${demo}/bin/system_profiler" <<'TOOL'
#!/bin/sh
awk -F '\t' '
  function device(r) { split(r, f, "\t"); out = out "          " f[5] ":\n              Address: " f[2] "\n              Minor Type: " f[3] "\n"; if (f[4] != "") { out = out "              Battery Level: " f[4] "%\n" } return out }
  { rows[NR] = $0; state[NR] = $1 }
  END {
    printf "Bluetooth:\n      Connected:\n"
    for (i = 1; i <= NR; i++) { if (state[i] == "connected") { out = ""; printf "%s", device(rows[i]) } }
    printf "      Not Connected:\n"
    for (i = 1; i <= NR; i++) { if (state[i] == "paired") { out = ""; printf "%s", device(rows[i]) } }
  }
' /Users/Shared/demo/devices.tsv
TOOL
cat >"${demo}/bin/blueutil" <<'TOOL'
#!/bin/sh
table=/Users/Shared/demo/devices.tsv
case "$1" in
--power)
  if [ "$#" -eq 1 ]; then
    cat /Users/Shared/demo/power
  else
    printf '%s\n' "$2" >/Users/Shared/demo/power
  fi
  ;;
--connect | --disconnect)
  state=connected
  [ "$1" = --connect ] || state=paired
  awk -F '\t' -v OFS='\t' -v a="$2" -v s="${state}" '$2 == a { $1 = s } { print }' "${table}" >"${table}.new"
  mv -f "${table}.new" "${table}"
  ;;
*) exit 1 ;;
esac
TOOL
chmod 755 "${demo}/bin/system_profiler" "${demo}/bin/blueutil"
tmux_path=$(command -v tmux)
ln -s "${tmux_path}" "${demo}/bin/tmux"
