# Ubuntu VM Quick Start

Use the `deploy/evilginx-container` branch for the Ubuntu VM deployment.

## Ubuntu Server

- Ubuntu 22.04 LTS or 24.04 LTS
- Fresh disposable VM
- Public IPv4 address
- Root or sudo access
- 2 vCPU / 4 GB RAM recommended
- 20 GB disk is plenty

## Network

- Inbound `22/tcp` for SSH
- Inbound `80/tcp`
- Inbound `443/tcp`
- Optional inbound `53/tcp` and `53/udp` if using Evilginx DNS handling
- DNS `A` record for the test domain pointing to the VM IP
- DNS wildcard `A` record for `*.domain` pointing to the VM IP

## Packages

```bash
sudo apt update
sudo apt install -y git curl ca-certificates gnupg lsb-release
```

## Docker

Install Docker Engine and Compose plugin:

```bash
curl -fsSL https://get.docker.com | sudo sh
sudo usermod -aG docker "$USER"
newgrp docker
docker --version
docker compose version
```

## Repo Setup

```bash
git clone https://github.com/iamfizlian/redteam-phase2.git
cd redteam-phase2
git checkout deploy/evilginx-container
cp .env.example .env
```

Edit `.env`:

```text
EVILGINX_DOMAIN=your-test-domain.com
EVILGINX_VM_IP=your.vm.public.ip
```

Then run:

```bash
03-evilginx/docker/preflight.sh
03-evilginx/docker/up.sh
```
