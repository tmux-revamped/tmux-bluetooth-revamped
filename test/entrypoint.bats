#!/usr/bin/env bats

setup() {
  ENTRY_OPTS="${BATS_TEST_TMPDIR}/opts"
  mkdir -p "${ENTRY_OPTS}"
  export ENTRY_OPTS
  tmux() {
    local verb="${1}"
    shift
    case "${verb}" in
      show-option) [[ -f "${ENTRY_OPTS}/${*: -1}" ]] && cat "${ENTRY_OPTS}/${*: -1}"; return 0 ;;
      set-option) printf '%s' "${3}" > "${ENTRY_OPTS}/${2}" ;;
      *) return 0 ;;
    esac
  }
  export -f tmux
  ENTRY="${BATS_TEST_DIRNAME}/../bluetooth-revamped.tmux"
}

@test "entrypoint - the status job runs the plugin from a path with a space and a quote" {
  # Arrange
  local root="${BATS_TEST_TMPDIR}/it's a dir" job
  mkdir -p "${root}/src"
  cp "${ENTRY}" "${root}/bluetooth-revamped.tmux"
  printf '#!/bin/sh\nprintf %%s "$1" > "$RAN_FILE"\n' > "${root}/src/bluetooth.sh"
  RAN_FILE="${BATS_TEST_TMPDIR}/ran"
  export RAN_FILE
  printf '%s' '#{bluetooth_count}' > "${ENTRY_OPTS}/status-right"
  bash "${root}/bluetooth-revamped.tmux"
  job="$(cat "${ENTRY_OPTS}/status-right")"
  job="${job#\#(}"

  # Act
  run sh -c "${job%)}"

  # Assert
  [ "${status}" -eq 0 ]
  [[ "$(cat "${RAN_FILE}")" == "count" ]]
}
