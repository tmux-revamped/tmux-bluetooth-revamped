#!/usr/bin/env bash

[[ -n "${_BLUETOOTH_REVAMPED_RENDER_LOADED:-}" ]] && return 0
_BLUETOOTH_REVAMPED_RENDER_LOADED=1

_BT_RENDER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${_BT_RENDER_DIR}/../tmux/tmux-ops.sh"

bluetooth_render_device() {
  [[ -z "${1}" ]] && { echo ""; return 0; }
  local sep out="" line
  sep=$(get_tmux_option "@bluetooth_revamped_separator" ", ")
  while IFS= read -r line; do
    [[ -z "${line}" ]] && continue
    [[ -n "${out}" ]] && out="${out}${sep}"
    out="${out}${line}"
  done <<< "${1}"
  local fmt
  fmt=$(get_tmux_option "@bluetooth_revamped_format" "%s")
  # shellcheck disable=SC2059
  printf "${fmt}" "${out}"
}

bluetooth_render_icon() {
  [[ -z "${1}" ]] && { echo ""; return 0; }
  get_tmux_option "@bluetooth_revamped_icon" "BT"
}

bluetooth_render_count() {
  [[ -z "${1}" ]] && { echo "0"; return 0; }
  local n=0 line
  while IFS= read -r line; do
    [[ -z "${line}" ]] && continue
    n=$(( n + 1 ))
  done <<< "${1}"
  echo "${n}"
}

bluetooth_render_min() {
  [[ -z "${1}" ]] && { echo ""; return 0; }
  local line best="" best_pct=101 pct
  while IFS= read -r line; do
    [[ -z "${line}" ]] && continue
    pct="${line##* }"
    case "${pct}" in
      *%) pct="${pct%\%}" ;;
      *) continue ;;
    esac
    [[ "${pct}" =~ ^[0-9]+$ ]] || continue
    if (( pct < best_pct )); then
      best_pct=${pct}
      best="${line}"
    fi
  done <<< "${1}"
  echo "${best}"
}

export -f bluetooth_render_device
export -f bluetooth_render_icon
export -f bluetooth_render_count
export -f bluetooth_render_min
