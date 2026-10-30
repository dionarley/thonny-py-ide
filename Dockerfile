# Thonny Python IDE in a container.
#
# The installation mirrors https://thonny.org/installer-for-linux, but without
# sudo/desktop launcher: Thonny lives in its own virtualenv at /opt/thonny.
#
# GUI access is provided either through a bind-mounted X11 socket (see run.sh)
# or, when no display is available, through Xvfb + x11vnc + noVNC on port 6080.

FROM docker.io/library/debian:bookworm-slim

ARG THONNY_VERSION=5.0.1
ARG APP_DIR=/opt/thonny
ARG USER_NAME=dev
ARG USER_UID=1000
ARG USER_GID=1000

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    PYTHONUNBUFFERED=1 \
    PATH=${APP_DIR}/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# System dependencies:
#   - python3-tk / python3-venv: required by Thonny and its helper venvs
#   - Xvfb, x11vnc, openbox, noVNC: headless fallback access
#   - fonts + X libs: Tk needs them to render any window at all
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      ca-certificates \
      curl \
      git \
      less \
      nano \
      openssh-client \
      python3 \
      python3-pip \
      python3-tk \
      python3-venv \
      fonts-dejavu-core \
      libfontconfig1 \
      libx11-6 \
      libxext6 \
      libxft2 \
      libxrender1 \
      libxss1 \
      openbox \
      x11vnc \
      xauth \
      xvfb \
      novnc \
      websockify \
      tini \
 && rm -rf /var/lib/apt/lists/* \
 && { getent group "${USER_GID}" >/dev/null 2>&1 || groupadd -g "${USER_GID}" "${USER_NAME}"; } \
 && useradd --create-home --uid "${USER_UID}" --gid "${USER_GID}" \
      --shell /bin/bash "${USER_NAME}"

# Same packages the official installer pulls in, minus the macOS/Windows-only
# ones (cryptography is already a transitive dependency of paramiko on Linux).
RUN python3 -m venv "${APP_DIR}" \
 && echo ";Existence of this file indicates that Python in this directory is private for Thonny" \
      > "${APP_DIR}/bin/thonny_python.ini" \
 && "${APP_DIR}/bin/python3" -m pip install --no-cache-dir --upgrade pip setuptools wheel \
 && "${APP_DIR}/bin/python3" -m pip install --no-cache-dir \
      'jedi==0.20.*' \
      'pyserial==3.5' \
      'pylint==4.1.*' \
      'docutils==0.23.*' \
      'mypy==2.4.*' \
      'asttokens==3.0.*' \
      'Send2Trash==2.1.*' \
      'esptool==5.6.*' \
      'paramiko==5.*' \
      'websockets==17.*' \
      'ptyprocess==0.7.*' \
      'dbus-next==0.2.*' \
      "thonny==${THONNY_VERSION}" \
 && "${APP_DIR}/bin/python3" -c \
      "import pathlib, tkinter, thonny; \
       print('Thonny', (pathlib.Path(thonny.__file__).parent / 'VERSION').read_text().strip(), '| Tk', tkinter.TkVersion)"

COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod 0755 /usr/local/bin/entrypoint.sh

EXPOSE 5900 6080
VOLUME ["/workspace"]

USER ${USER_NAME}
WORKDIR /workspace

ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/entrypoint.sh"]
CMD ["thonny"]
