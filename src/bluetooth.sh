#!/usr/bin/env bash

PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

export CACHE_PREFIX="bluetooth_revamped"
export PLUGIN_LOG_NS="bluetooth-revamped"

# shellcheck source=/dev/null
source "${PLUGIN_DIR}/src/lib/utils/has-command.sh"
# shellcheck source=/dev/null
source "${PLUGIN_DIR}/src/lib/utils/platform.sh"
# shellcheck source=/dev/null
source "${PLUGIN_DIR}/src/lib/tmux/tmux-ops.sh"
# shellcheck source=/dev/null
source "${PLUGIN_DIR}/src/lib/utils/cache.sh"
# shellcheck source=/dev/null
source "${PLUGIN_DIR}/src/lib/bluetooth/bluetooth.sh"
# shellcheck source=/dev/null
source "${PLUGIN_DIR}/src/lib/bluetooth/render.sh"

BLUETOOTH_DEFAULT_INTERVAL="30"

bluetooth_max_age() {
  local interval
  interval=$(get_tmux_option "@bluetooth_revamped_interval" "${BLUETOOTH_DEFAULT_INTERVAL}")
  [[ "${interval}" =~ ^[0-9]+$ ]] || interval="${BLUETOOTH_DEFAULT_INTERVAL}"
  echo "${interval}"
}

bluetooth_refresh() {
  cache_set device "$(read_bluetooth)"
}

bluetooth_tick() {
  cache_refresh_if_stale device "$(bluetooth_max_age)" bluetooth_refresh
}

main() {
  local cmd="${1:-}"

  if [[ "${cmd}" == "refresh" ]]; then
    bluetooth_refresh
    return 0
  fi

  bluetooth_tick

  case "${cmd}" in
    device) bluetooth_render_device "$(cache_get device)" ;;
    icon)   bluetooth_render_icon "$(cache_get device)" ;;
    count)  bluetooth_render_count "$(cache_get device)" ;;
    min)    bluetooth_render_min "$(cache_get device)" ;;
    *)      return 0 ;;
  esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
