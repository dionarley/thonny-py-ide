# Licenças de terceiros

Este repositório contém apenas arquivos de configuração (Dockerfile, scripts e
documentação). A imagem gerada **agrega** programas de terceiros, cada um
distribuído sob sua própria licença. Nada aqui incorpora o código dessas
bibliotecas ao código deste projeto: elas são instaladas como pacotes
independentes e executadas como processos separados.

## Programas instalados na imagem

| Componente | Versão | Licença |
|------------|--------|---------|
| [Thonny](https://thonny.org) | 5.0.1 | MIT |
| [jedi](https://github.com/davidhalter/jedi) | 0.20.x | MIT |
| [pyserial](https://github.com/pyserial/pyserial) | 3.5 | BSD-3-Clause |
| [pylint](https://github.com/pylint-dev/pylint) | 4.1.x | GPL-2.0-or-later |
| [docutils](https://docutils.sourceforge.io) | 0.23.x | Public Domain / BSD-2-Clause / GPL-2.0 (tri-licença) |
| [mypy](https://github.com/python/mypy) | 2.4.x | MIT |
| [asttokens](https://github.com/gristlabs/asttokens) | 3.0.x | Apache-2.0 |
| [Send2Trash](https://github.com/arsenetar/send2trash) | 2.1.x | BSD-3-Clause |
| [esptool](https://github.com/espressif/esptool) | 5.6.x | GPL-2.0-or-later |
| [paramiko](https://github.com/paramiko/paramiko) | 5.x | LGPL-2.1-or-later |
| [cryptography](https://github.com/pyca/cryptography) | (transitiva do paramiko) | Apache-2.0 / BSD-3-Clause |
| [websockets](https://github.com/python-websockets/websockets) | 17.x | BSD-3-Clause |
| [ptyprocess](https://github.com/pexpect/ptyprocess) | 0.7.x | ISC |
| [dbus-next](https://github.com/altdesktop/python-dbus-next) | 0.2.x | MIT |

## Pacotes do sistema (Debian bookworm)

| Pacote | Licença |
|--------|---------|
| Python 3.11 / Tk (`python3`, `python3-tk`) | PSF-2.0 / Tcl-Tk (BSD-style) |
| Xvfb | MIT |
| x11vnc | GPL-2.0-or-later |
| openbox | GPL-2.0-or-later |
| noVNC | MPL-2.0 |
| websockify | LGPL-3.0-or-later |
| tini | MIT |
| utilitários Debian/GNU (`bash`, `git`, `curl`, `less`, `nano`, `openssh-client`) | GPL/LGPL/BSD/Apache conforme o pacote |

## Observações

- **pylint** e **esptool** são GPL, mas são executados como programas
  separados (via subprocesso), não linkados ao código deste repositório nem ao
  Thonny. Distribuí-los dentro de uma imagem é permitido pela GPL; o
  cumprimento das obrigações (texto da licença e oferta do código-fonte)
  depende do repositório da distro/pacote de origem, referenciado acima.
- **paramiko** é LGPL e é usado pelo Thonny como biblioteca separada, sem
  modificações.
- Se você redistribuir a imagem, mantenha os avisos de copyright e as licenças
  dos pacotes (elas permanecem em `/usr/share/doc/*/copyright` e nos
  metadados do virtualenv em `/opt/thonny`).

Este documento é informativo e não substitui os textos originais das licenças.
