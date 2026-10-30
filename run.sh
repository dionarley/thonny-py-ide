#!/usr/bin/env bash
# Helper for building and running the Thonny container.
#
#   ./run.sh build            build the image
#   ./run.sh x11 [file.py]    run with the host X11 display (Linux desktop)
#   ./run.sh vnc [file.py]    run headless and open it in the browser (noVNC)
#   ./run.sh shell            open a bash shell inside the image
#
# Honours ENGINE=podman|docker, IMAGE=<tag> and SCREEN=<WxHxD>.
set -euo pipefail

cd "$(dirname "$0")"

ENGINE="${ENGINE:-}"
if [ -z "${ENGINE}" ]; then
    if command -v podman >/dev/null 2>&1; then
        ENGINE=podman
    elif command -v docker >/dev/null 2>&1; then
        ENGINE=docker
    else
        echo "error: neither podman nor docker was found" >&2
        exit 1
    fi
fi

IMAGE="${IMAGE:-thonny-ide:5.0.1}"
SCREEN="${SCREEN:-1440x900x24}"
WORKSPACE="$(pwd)/workspace"

USERNS_ARGS=()
if [ "${ENGINE}" = "podman" ] && [ "$(id -u)" -ne 0 ]; then
    USERNS_ARGS=(--userns=keep-id)
fi

run_common=(run --rm -it --name thonny
    "${USERNS_ARGS[@]}"
    --shm-size=512m
    -e "SCREEN=${SCREEN}"
    -v "${WORKSPACE}:/workspace:rw"
    -w /workspace)

build() {
    mkdir -p "${WORKSPACE}"
    "${ENGINE}" build \
        --build-arg "USER_UID=$(id -u)" \
        --build-arg "USER_GID=$(id -g)" \
        -t "${IMAGE}" .
}

x11() {
    local auth_args=()
    local auth_file="${XAUTHORITY:-${HOME}/.Xauthority}"
    if [ -n "${DISPLAY:-}" ] && [ -f "${auth_file}" ]; then
        auth_args=(
            -e "DISPLAY=${DISPLAY}"
            -e "XAUTHORITY=/home/dev/.Xauthority"
            -v "${auth_file}:/home/dev/.Xauthority:ro"
            -v /tmp/.X11-unix:/tmp/.X11-unix:rw
        )
    else
        echo "warning: no usable DISPLAY/Xauthority, falling back to VNC mode" >&2
        vnc "$@"
        return
    fi

    "${ENGINE}" "${run_common[@]}" \
        "${auth_args[@]}" \
        "${IMAGE}" thonny "$@"
}

vnc() {
    "${ENGINE}" "${run_common[@]}" \
        -p 127.0.0.1:6080:6080 \
        -p 127.0.0.1:5900:5900 \
        "${IMAGE}" thonny "$@"
}

case "${1:-}" in
    build) shift; build "$@" ;;
    x11)   shift; x11 "$@" ;;
    vnc)   shift; vnc "$@" ;;
    shell) shift; "${ENGINE}" "${run_common[@]}" "${IMAGE}" bash "$@" ;;
    *)
        cat >&2 <<EOF
usage: $0 {build|x11|vnc|shell} [args...]

  build            build ${IMAGE}
  x11  [file.py]   open the IDE on the host X11 display
  vnc  [file.py]   open the IDE headless, browse http://localhost:6080/vnc.html
  shell            run bash inside the image
EOF
        exit 2
        ;;
esac
