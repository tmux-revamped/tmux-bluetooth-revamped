#!/bin/sh
set -eu

: "${SCREENS_REPO:?}"
demo=/Users/Shared/demo
rm -rf "${demo}"
mkdir -p "${demo}/home" "${demo}/bin"
cat >"${demo}/devices.txt" <<'DEVICES'
Bluetooth:
    Connected:
        AirPods Pro:
            Left Battery Level: 90%
            Right Battery Level: 85%
            Case Battery Level: 100%
        Magic Keyboard:
            Address: 00-22
        MX Master 3S:
            Battery Level: 50%
DEVICES
printf '#!/bin/sh\ncat /Users/Shared/demo/devices.txt\n' >"${demo}/bin/system_profiler"
chmod 755 "${demo}/bin/system_profiler"
tmux_path=$(command -v tmux)
ln -s "${tmux_path}" "${demo}/bin/tmux"
