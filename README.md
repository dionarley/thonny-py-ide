# Thonny Python IDE em container

Imagem Debian com o [Thonny](https://thonny.org) 5.0.1 instalado em um
virtualenv próprio (`/opt/thonny`), com a mesma lista de dependências usada
pelo instalador oficial (`install_from_net`).

A IDE pode ser usada de duas formas:

| Modo | Quando usar | Como acessar |
|------|-------------|--------------|
| **X11** | Você está num desktop Linux com servidor X | A janela abre direto no seu desktop |
| **VNC/noVNC** | Servidor sem tela, SSH, Windows/macOS, ou X11 sem permissão | Navegador em `http://localhost:6080/vnc.html` |

## Estrutura

```
Dockerfile              imagem (Thonny + Xvfb + x11vnc + noVNC)
docker/entrypoint.sh    decide entre X11 e modo headless
run.sh                  atalho para build/execução
docker-compose.yml      modo VNC via docker compose / podman-compose
workspace/              seus projetos (montado em /workspace)
install_from_net        script oficial do thonny.org (referência)
```

## Uso rápido (podman ou docker)

O `run.sh` detecta automaticamente `podman` ou `docker`
(para forçar: `ENGINE=docker ./run.sh ...`).

```bash
./run.sh build          # constrói a imagem (demora na primeira vez)
./run.sh x11            # abre a IDE usando o X11 do host
./run.sh x11 workspace/hello.py
./run.sh vnc            # modo headless -> http://localhost:6080/vnc.html
./run.sh shell          # bash dentro do container
```

### NixOS + podman

O modo X11 funciona com o socket `/tmp/.X11-unix` montado e o cookie do
`~/.Xauthority` copiado para dentro do container. Se aparecer
`Authorization required`, libere o acesso antes de rodar:

```bash
xhost +si:localuser:$(whoami)   # ou: xhost +local:
```

O `run.sh` já usa `--userns=keep-id`, então os arquivos criados em
`workspace/` ficam com o seu UID no host.

### docker compose / podman-compose

```bash
mkdir -p workspace
podman-compose up --build      # ou: docker compose up --build
# abra http://localhost:6080/vnc.html
```

As portas 6080 (noVNC) e 5900 (VNC) ficam publicadas apenas em `127.0.0.1`.

## Detalhes

- **Usuário**: `dev` (UID/GID iguais aos do host, passados como build args).
- **Projetos**: `/workspace` é o diretório de trabalho e o volume padrão.
- **Thonny**: `/opt/thonny/bin/thonny`, também no `PATH`.
- **Python do Thonny**: `/opt/thonny/bin/python3` — pacotes extras para os
  seus programas devem ser instalados no interpretador que você escolher no
  menu *Run > Configure interpreter* (o venv do sistema ou um novo).
- **Headless**: `Xvfb :1` + `openbox` + `x11vnc` (localhost) + `websockify`.
  Resolução ajustável com `SCREEN=1920x1080x24 ./run.sh vnc`.

### Variáveis de ambiente

| Variável | Padrão | Descrição |
|----------|--------|-----------|
| `SCREEN` | `1440x900x24` | resolução do display virtual |
| `NOVNC_PORT` | `6080` | porta HTTP do noVNC |
| `VNC_PORT` | `5900` | porta do x11vnc (interna) |
| `THONNY_VERSION` | `5.0.1` | versão instalada (build arg) |

Exemplo:

```bash
podman build --build-arg THONNY_VERSION=5.0.1 -t thonny-ide:5.0.1 .
SCREEN=1920x1080x24 ./run.sh vnc
```

## Atualizar o Thonny

O instalador oficial é a fonte da verdade para a lista de dependências. Para
trocar a versão:

```bash
curl -fsSL https://thonny.org/installer-for-linux | grep -E "VERSION=|pip install"
```

Depois ajuste `ARG THONNY_VERSION` e os pins no `Dockerfile` e reconstrua.

## Solução de problemas

- **`cannot open display`**: confirme `echo $DISPLAY` e se
  `/tmp/.X11-unix/X0` existe; em Wayland puro rode `./run.sh vnc`.
- **Tela preta no noVNC**: aguarde alguns segundos (Xvfb + openbox sobem antes
  do Thonny) e recarregue a página; logs em `/tmp/*.log` dentro do container.
- **Permissão nos arquivos**: construa com `--build-arg USER_UID=$(id -u)
  --build-arg USER_GID=$(id -g)` (o `run.sh build` já faz isso).
