#!/usr/bin/env bash

PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BT_CMD="${PLUGIN_DIR}/src/bluetooth.sh"
BT_CMD_ARG="$(printf '%q' "${BT_CMD}")"
hash="#"
BT_CMD_ARG="${BT_CMD_ARG//"${hash}"/${hash}${hash}}"

shopt -u patsub_replacement 2>/dev/null || true

placeholders=(
  "\#{bluetooth}"
  "\#{bluetooth_icon}"
  "\#{bluetooth_count}"
  "\#{bluetooth_min}"
)

commands=(
  "#(${BT_CMD_ARG} device)"
  "#(${BT_CMD_ARG} icon)"
  "#(${BT_CMD_ARG} count)"
  "#(${BT_CMD_ARG} min)"
)

interpolate() {
  local value="${1}"
  local i
  for (( i = 0; i < ${#placeholders[@]}; i++ )); do
    value="${value//${placeholders[i]}/${commands[i]}}"
  done
  echo "${value}"
}

update_option() {
  local option="${1}"
  local current
  current=$(tmux show-option -gqv "${option}")
  tmux set-option -gq "${option}" "$(interpolate "${current}")"
}

chmod +x "${BT_CMD}" 2>/dev/null || true

update_option "status-left"
update_option "status-right"
