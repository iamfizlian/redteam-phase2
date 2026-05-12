# Evilginx Container Deployment

This directory supports a disposable VM deployment for authorized AitM control validation. It builds upstream Evilginx and runs it with host networking so ports `80`, `443`, and `53` can bind on the VM.

It intentionally does not include working Microsoft 365 phishlets, credential collection pages, stolen-token replay automation, or secrets.

## VM Requirements

- Debian 12 or Ubuntu 22.04+
- Docker Engine with Compose plugin
- Public IP address
- DNS `A` record and wildcard `A` record pointing to the VM
- Inbound `22/tcp`, `80/tcp`, `443/tcp`, and, if needed, `53/tcp` and `53/udp`

## Start

```bash
git clone https://github.com/iamfizlian/redteam-phase2.git
cd redteam-phase2
git checkout deploy/evilginx-container
cp .env.example .env
```

Edit `.env`:

```text
EVILGINX_DOMAIN=<test-domain>
EVILGINX_VM_IP=<vm-public-ip>
```

Create runtime directories:

```bash
mkdir -p 03-evilginx/docker/runtime/phishlets
mkdir -p 03-evilginx/docker/runtime/logs
mkdir -p 03-evilginx/docker/runtime/config
```

Start:

```bash
03-evilginx/docker/preflight.sh
03-evilginx/docker/up.sh
docker compose -f 03-evilginx/docker/compose.yml logs -f
```

Attach:

```bash
docker attach evilginx-lab
```

Detach with `Ctrl-p Ctrl-q`.

## Stop

```bash
03-evilginx/docker/down.sh
```

Destroy the VM after the test window.
