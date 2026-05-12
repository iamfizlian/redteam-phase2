# Evilginx AitM Validation Runbook

This runbook is for authorized Microsoft 365 control validation in a dedicated lab tenant. It does not include a working Microsoft 365 phishlet, credential collection page, stolen-token replay automation, or tenant secrets.

## Objective

Validate whether your controls prevent or detect adversary-in-the-middle browser session theft and replay.

Primary pass/fail questions:

- Does phishing-resistant MFA stop the sign-in?
- Does compliant-device Conditional Access block replay from an unmanaged host?
- Does CAE strict location enforcement revoke the session quickly when replay occurs from an untrusted IP?
- Do Defender XDR, Identity Protection, Sentinel, and Advanced Hunting show useful evidence?
- Can sessions be revoked and the user returned to a clean state?

## Required Scope

Define this before creating infrastructure:

| Item | Value |
|---|---|
| Tenant ID | |
| Test user UPNs | |
| Test window | |
| Authorized operator | |
| VM public IP | |
| Test domain | |
| Defender/Sentinel workspace | |
| Emergency contact | |

## Preflight

1. Deploy detections first:

   ```bash
   make split-kql
   ```

2. Deploy the generated KQL queries from `generated/kql/`.
3. Confirm test users are excluded from production-impacting policies only where explicitly approved.
4. Confirm you have at least these policy states available for comparison:

| Control | Baseline | Enforced |
|---|---|---|
| FIDO2/passkey or WHfB | | |
| Require compliant device | | |
| CAE strict location | | |
| Token Protection for supported native apps | | |
| Authentication strength | | |

5. Confirm DNS points the test domain and wildcard record to the disposable VM:

```text
A     <test-domain>      <vm-public-ip>
A     *.<test-domain>    <vm-public-ip>
```

## VM Deployment

Use a fresh Debian 12 or Ubuntu 22.04+ VM with a public IP. Open only the ports needed for this test:

| Port | Protocol | Purpose |
|---|---|---|
| 22 | TCP | SSH administration |
| 80 | TCP | HTTP and ACME challenge |
| 443 | TCP | HTTPS |
| 53 | TCP/UDP | DNS if using Evilginx DNS handling |

Clone the container branch:

```bash
git clone https://github.com/iamfizlian/redteam-phase2.git
cd redteam-phase2
git checkout deploy/evilginx-container
cp .env.example .env
```

Fill in:

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

Place only authorized lab phishlets in `03-evilginx/docker/runtime/phishlets/`. This repository intentionally does not provide them.

Start the container:

```bash
03-evilginx/docker/preflight.sh
03-evilginx/docker/up.sh
docker compose -f 03-evilginx/docker/compose.yml logs -f
```

Attach to the Evilginx console:

```bash
docker attach evilginx-lab
```

Detach without stopping the container with `Ctrl-p Ctrl-q`.

## Manual Configuration

Inside the Evilginx console, configure only values approved for the lab:

```text
config domain <test-domain>
config ipv4 external <vm-public-ip>
```

Do not use production domains, production users, or third-party tenants.

## Validation Matrix

Record each result in `findings-report-template.md`.

| Scenario | Expected secure result | Actual |
|---|---|---|
| FIDO2/passkey user attempts auth | AitM flow fails before usable session capture | |
| Captured browser session replayed from unmanaged host | Blocked by compliant-device CA | |
| Captured browser session replayed from untrusted IP | CAE/location revokes quickly | |
| Native app token replay with Token Protection | Blocked for supported apps | |
| Defender XDR / Identity Protection | Alert or risky sign-in evidence appears | |
| Sentinel / Advanced Hunting | Relevant detections fire | |

## Evidence Collection

Capture:

- sign-in log correlation IDs
- test user UPN
- source and replay IPs
- user agent values
- Conditional Access policy decisions
- Defender incident or alert IDs
- KQL result screenshots or exported rows
- session revocation timestamps

Do not commit captured cookies, tokens, logs containing secrets, `.env`, or screenshots with sensitive values.

## Cleanup

1. Stop the container:

   ```bash
   03-evilginx/docker/down.sh
   ```

2. Revoke sessions for test users.
3. Remove suspicious OAuth grants created during testing.
4. Destroy the VM.
5. Delete or release the test domain if it will not be reused.
6. Preserve only sanitized evidence needed for the report.

## Pass Criteria

The environment is considered resilient only if replay from outside approved device/location context is blocked or rapidly revoked and detection evidence is available to responders.
