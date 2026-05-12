# 03 - AitM Phishing Test (Evilginx)

## What this tests

A reverse proxy sitting between the victim and `login.microsoftonline.com` captures the post-MFA session cookie. The cookie is then replayed in the attacker's browser to access M365 as the victim. **This is the test for the browser-session gap in Token Protection.**

## Setup

Run `deploy.sh` on a fresh Debian/Ubuntu cloud VM. The script installs Evilginx upstream from the public repo, firewalls the box, and gives you next-step instructions.

```bash
curl -O https://raw.githubusercontent.com/.../deploy.sh   # or scp this file
sudo bash deploy.sh
```

## Test execution outline

After deployment:

1. Register a credible-looking domain (e.g., `login-microsoftonline-update.com`)
2. Point DNS (apex + wildcard) at the Evilginx VM
3. Configure Evilginx via its CLI (commands printed by deploy.sh)
4. Enable a working o365 phishlet (see "Phishlet" below)
5. Generate a lure URL
6. Deliver to victim test user
7. Capture session cookie when victim authenticates through the proxy
8. Replay cookie in attacker browser via Cookie Editor extension → `outlook.office.com`

## Phishlet

The upstream `o365` phishlet in Evilginx is intentionally outdated to deter abuse. For a working test you'll need to either:
- Take Kuba Gretzky's official **Evilginx Mastery** course (the legitimate path; covers building/maintaining phishlets for red team use)
- Build a phishlet yourself based on the syntax docs in the Evilginx repo

This kit does not bundle phishlets.

## Test matrix — run each combination

The whole point of this vector is to verify which **layered** controls actually hold up. Run the same Evilginx capture, then attempt cookie replay under different conditions:

| Replay against | Token Protection state | Expected | Actual |
|---|---|---|---|
| outlook.office.com (web) from attacker box, no other controls | n/a — browser unsupported | ✅ Succeeds | __ |
| outlook.office.com (web) from attacker box outside named location | n/a + CAE strict location | ❌ Token dies <5 min | __ |
| outlook.office.com (web) from attacker box, requireCompliantDevice CA on | n/a | ❌ Blocked | __ |
| Outlook desktop with refresh token, Token Protection CA enforced | Native + bound | ❌ Blocked | __ |
| Teams desktop with refresh token, Token Protection CA enforced | Native + bound | ❌ Blocked | __ |
| Victim is FIDO2/passkey user (victim04) | Phishing-resistant MFA | ❌ Auth fails at MFA — Evilginx can't proxy the assertion | __ |

This is your scorecard. Fill in **Actual** and that's your finding for this vector.

## What to monitor during

- Entra ID sign-in logs filtered to victim user — record session ID, IP, UA
- Defender XDR alerts queue — does AiTM Attack Disruption fire?
- Defender for Cloud Apps — Impossible Travel? Unusual UA?
- AppGate gateway logs (if M365 traffic is forced through AppGate)

## Closing the gap

Effective against AitM in priority order:
1. **Phishing-resistant MFA (FIDO2/passkey/WHfB)** — kills the attack at the MFA step, no replay possible
2. **Compliant device requirement in CA** — token replay from unmanaged box fails
3. **CAE strict location enforcement** — token revoked within minutes of replay from out-of-policy IP
4. Defender XDR Automatic Attack Disruption — auto-revokes session on confirmed AitM detection
