#!/usr/bin/env bash
# Entry point for the Thonny container.
#
#   thonny [file]        -> start the IDE (default)
#   /path/to/script.py   -> open that file in the IDE
#   bash | sh | any cmd  -> execute the command as-is
#
# If DISPLAY points at an X socket that was bind-mounted into the container the
# IDE uses it directly. Otherwise a virtual display is started, exposed through
# x11vnc on 5900 and noVNC on 6080 (http://localhost:6080/vnc.html).
set -euo pipefail

log() { printf '[thonny] %s\n' "$*" >&2; }

if [ "$#" -eq 0 ]; then
    set -- thonny
fi

case "$1" in
    thonny|*/thonny)
        shift
        ide_args=("$@")
        ;;
    *.py|*.pyw)
        ide_args=("$@")
        ;;
    *)
        exec "$@"
        ;;
esac

x11_socket_for_display() {
    local display="${1#*:}"   # drop the optional host part
    display="${display%%.*}"  # drop the screen number
    printf '/tmp/.X11-unix/X%s' "${display}"
}

if [ -n "${DISPLAY:-}" ] && [ -S "$(x11_socket_for_display "${DISPLAY}")" ]; then
    log "using host X11 display ${DISPLAY}"
    exec thonny "${ide_args[@]}"
fi

SCREEN="${SCREEN:-1440x900x24}"
VNC_PORT="${VNC_PORT:-5900}"
NOVNC_PORT="${NOVNC_PORT:-6080}"
export DISPLAY=:1

log "starting virtual display :1 (${SCREEN})"
Xvfb :1 -screen 0 "${SCREEN}" -nolisten tcp >/tmp/xvfb.log 2>&1 &

for _ in $(seq 1 100); do
    [ -S /tmp/.X11-unix/X1 ] && break
    sleep 0.1
done

openbox >/tmp/openbox.log 2>&1 &
x11vnc -display :1 -forever -shared -nopw -localhost \
    -rfbport "${VNC_PORT}" -quiet >/tmp/x11vnc.log 2>&1 &
websockify --web=/usr/share/novnc "${NOVNC_PORT}" "localhost:${VNC_PORT}" \
    >/tmp/novnc.log 2>&1 &

log "noVNC ready at http://localhost:${NOVNC_PORT}/vnc.html"

exec thonny "${ide_args[@]}"
