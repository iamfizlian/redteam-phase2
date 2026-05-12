# Deployment Guide

This repository is deployable as an authorized lab validation kit. It intentionally does not include working phishlets, credential collection pages, stolen-token replay automation, or payloads.

## 1. Clone and Validate

```bash
git clone https://github.com/iamfizlian/redteam-phase2.git
cd redteam-phase2
cp .env.example .env
make validate
```

Fill in `.env` with your lab tenant, test users, and infrastructure notes. Do not commit `.env`.

## 2. Deploy Detections First

Split the KQL pack into one file per query:

```bash
make split-kql
```

Open the files in `generated/kql/` and deploy them through Microsoft Sentinel or Defender XDR Advanced Hunting. Baseline the queries before running any test vector.

## 2.1. Install Optional Operator Tooling

Python tooling:

```bash
python3 -m venv .venv
. .venv/bin/activate
pip install -r requirements.txt
```

PowerShell tooling:

```powershell
Install-Module TokenTacticsV2 -Scope CurrentUser
Install-Module AADInternals -Scope CurrentUser
Install-Module Microsoft.Graph -Scope CurrentUser
```

## 3. Run Test Vectors

Use the vectors in this order:

1. `01-oauth-consent/`
2. `02-device-code/`
3. `03-evilginx/`
4. `04-endpoint/`

Each folder contains the operator checklist for that vector. Keep all execution inside a tenant and host set you own or have explicit written authorization to test.

## 4. Evilginx Infrastructure

`03-evilginx/deploy.sh` installs upstream Evilginx on a fresh Debian or Ubuntu VM and configures the firewall. It does not ship a working Microsoft 365 phishlet.

For containerized VM deployment, use the separate branch:

```bash
git checkout deploy/evilginx-container
```

Then follow `03-evilginx/RUNBOOK.md`.

Expected VM flow:

```bash
scp 03-evilginx/deploy.sh root@<vm-ip>:/root/deploy.sh
ssh root@<vm-ip>
bash /root/deploy.sh
```

After validation, destroy the VM and document its IP address, domain, and test window for blue-team correlation.

## 5. Package a Release

```bash
make package
```

The release zip is written to `generated/redteam-phase2.zip`.

## Missing Before This Pass

- No single validation command.
- No config template for tenant, user, domain, or VM values.
- No KQL splitting workflow for deployment as individual analytic rules.
- No package target.
- No `.gitignore` for token, cookie, PRT, and report artifacts.
- Quickstart text was copied from chat formatting and was not reliable markdown.
