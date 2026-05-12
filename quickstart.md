# Quickstart

Use this kit only in a tenant, hosts, and user population you own or have explicit written authorization to test.

## 1. Validate the Repo

```bash
cp .env.example .env
make validate
```

Edit `.env` with your lab tenant ID, tenant domain, test user, and any infrastructure values.

## 2. Deploy Detections First

```bash
make split-kql
```

Deploy the generated queries from `generated/kql/` into Microsoft Sentinel or Defender XDR Advanced Hunting. Run them once before testing to establish baseline noise.

Priority baseline queries:

- `1.1` consent grants
- `2.1` device code authentications
- `3.2` Token Protection enforcement
- `4.1` endpoint token-store access

## 3. Run Vectors in Order

| Order | Folder | Setup level | Purpose |
|---|---|---|---|
| 1 | `01-oauth-consent/` | Low | Validate illicit consent controls and app governance |
| 2 | `02-device-code/` | Low | Validate device code flow blocking |
| 3 | `03-evilginx/` | High | Validate AitM-resistant controls in an authorized lab |
| 4 | `04-endpoint/` | High | Validate token replay controls after endpoint access |

Each folder has its own README and scorecard.

## 4. Evilginx VM Setup

For the AitM infrastructure validation only:

```bash
scp 03-evilginx/deploy.sh root@<vm-ip>:/root/deploy.sh
ssh root@<vm-ip>
bash /root/deploy.sh
```

The script installs upstream Evilginx and configures host firewall rules. It does not include a working Microsoft 365 phishlet.

## 5. Capture Results

Use `findings-report-template.md` during testing. Do not wait until the end; record:

- test window
- test users
- attacker IPs and domains
- controls enabled
- expected vs actual outcomes
- detection query results
- remediation decisions

## 6. Package for Distribution

```bash
make package
```

The zip is created at `generated/redteam-phase2.zip`.
