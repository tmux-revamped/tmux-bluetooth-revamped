#!/usr/bin/env bash

PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BT_CMD="${PLUGIN_DIR}/src/bluetooth.sh"

placeholders=(
  "\#{bluetooth}"
  "\#{bluetooth_icon}"
  "\#{bluetooth_count}"
  "\#{bluetooth_min}"
)

commands=(
  "#(${BT_CMD} device)"
  "#(${BT_CMD} icon)"
  "#(${BT_CMD} count)"
  "#(${BT_CMD} min)"
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
