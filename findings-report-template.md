# M365 Token Theft Red Team — Findings Report

**Tenant:** `<dev-tenant-name>.onmicrosoft.com`
**Test window:** `<YYYY-MM-DD HH:MM>` → `<YYYY-MM-DD HH:MM>`
**Tester:** `<name>`
**Test users:** `victim01` (managed/browser), `victim02` (managed/native), `victim03` (unmanaged), `victim04` (FIDO2)
**Attacker infrastructure:** `<VM IP>`, `<phishing domain>`, `<attacker tenant ID>`

---

## Executive Summary

`<3–5 sentences. Lead with what worked (most critical), then what held. Quantify where possible.>`

Example template:
> Of four token theft vectors tested against the dev tenant, **N succeeded** and **N were blocked** by existing controls. The highest-impact gap is `<vector>`, which succeeded because `<root cause>`. Recommended priority remediation is `<top 1–2 items>`.

---

## Vector 1 — OAuth Illicit Consent Grant

**Result:** `[ SUCCESS / PARTIAL / BLOCKED ]`

### Compromise details
- Identity compromised: `<UPN>`
- Time from phishing click to captured refresh token: `<minutes>`
- Tokens obtained: `[ access / refresh / both ]`
- Scopes obtained: `<list>`
- Refresh token still valid at +24h: `[ yes / no ]`
- Refresh token survived victim password reset: `[ yes / no ]`
- Refresh token survived `Revoke-MgUserSignInSession`: `[ yes / no ]`

### Control performance
| Control | Status | Evidence |
|---|---|---|
| User consent restriction (verified publisher only) | `[ effective / ineffective / not configured ]` | `<screenshot or log ref>` |
| Admin consent workflow | `[ effective / ineffective / not configured ]` | |
| Defender app governance alert | `[ fired / did not fire ]` | `<alert ID>` |
| Identity Protection risk elevation | `[ fired / did not fire ]` | |

### Detection performance
- KQL queries that surfaced this: `<list query IDs from detection pack>`
- Time-to-detect: `<minutes after compromise>`
- Alerts fired: `<list>`
- Queries that missed it: `<list>` → recommend tuning

### Recommended remediation
1. `<priority 1>`
2. `<priority 2>`

---

## Vector 2 — Device Code Flow Phishing

**Result:** `[ SUCCESS / PARTIAL / BLOCKED ]`

### Compromise details
- Identity compromised: `<UPN>`
- Client ID used: `<GUID + description>`
- Scope captured: `<scope>`
- Time from code delivery to token capture: `<minutes>`
- Refresh token replay survived +1h / +24h / password reset: `<y/n/y/n>`

### Control performance
| Control | Status | Evidence |
|---|---|---|
| CA "Authentication Flows" blocks device code | `[ effective / ineffective / not configured ]` | |
| Compliant device requirement | `[ effective / ineffective / not configured ]` | |
| CAE strict location revoked replay | `[ effective / ineffective / not configured ]` | `<time-to-revocation>` |
| Identity Protection risk elevation | `[ fired / did not fire ]` | |

### Detection performance
- KQL queries that surfaced this: `<list>`
- Time-to-detect: `<minutes>`
- Alerts fired: `<list>`

### Recommended remediation
1.
2.

---

## Vector 3 — AitM Phishing (Evilginx)

**Result:** `[ SUCCESS / PARTIAL / BLOCKED ]`

### Replay matrix
| Replay target | Conditions | Expected | Actual |
|---|---|---|---|
| outlook.office.com (web), attacker box, no extra controls | Browser session | Succeeds | `__` |
| outlook.office.com (web), attacker IP outside named location, CAE strict on | Browser + CAE | Token dies <5 min | `__` |
| outlook.office.com (web), requireCompliantDevice CA on | Browser + device CA | Blocked | `__` |
| Outlook desktop refresh token, Token Protection enforced | Native bound | Blocked | `__` |
| Teams desktop refresh token, Token Protection enforced | Native bound | Blocked | `__` |
| Same lure against `victim04` (FIDO2/passkey) | Phish-resistant MFA | Auth fails at MFA | `__` |

### Compromise details (where capture succeeded)
- Identity compromised: `<UPN>`
- Session cookies captured: `<ESTSAUTH / ESTSAUTHPERSISTENT / etc.>`
- Time from lure click to cookie capture: `<seconds/minutes>`
- Mailbox accessed from attacker browser: `[ yes / no ]`
- Persistence (cookie still valid at +Xh): `<duration>`

### Control performance
| Control | Status | Evidence |
|---|---|---|
| Phishing-resistant MFA (victim04) | `[ effective / ineffective / not configured ]` | |
| requireCompliantDevice CA | `[ effective / ineffective / not configured ]` | |
| CAE strict location | `[ effective / ineffective / not configured ]` | `<time-to-revocation>` |
| Defender XDR Automatic Attack Disruption | `[ fired / did not fire ]` | |
| Defender for Cloud Apps Impossible Travel | `[ fired / did not fire ]` | |
| AppGate gateway log evidence | `<traffic seen? IPs?>` | |

### Detection performance
- KQL queries that surfaced this: `<list>`
- Time-to-detect: `<minutes>`
- Alerts fired: `<list>`

### Recommended remediation
1.
2.

---

## Vector 4 — Endpoint Token Theft

**Result (per sub-test):**
- 4a PRT replay: `[ SUCCESS / PARTIAL / BLOCKED ]`
- 4b Browser cookie replay (web): `[ SUCCESS / PARTIAL / BLOCKED ]`
- 4c MSAL/WAM cache replay (native): `[ SUCCESS / PARTIAL / BLOCKED ]`

### Compromise details
| Sub-test | Artifact | Replay result on attacker box | Replay result on different managed box |
|---|---|---|---|
| 4a | PRT + session key | `__` | `__` |
| 4b | ESTSAUTH cookies | `__` | n/a |
| 4c | MSAL refresh tokens | `__` | `__` |

### Control performance
| Control | Status | Evidence |
|---|---|---|
| Token Protection CA (native apps) | `[ effective / ineffective / not configured ]` | |
| CAE strict location | `[ effective / ineffective / not configured ]` | |
| Compliant device CA | `[ effective / ineffective / not configured ]` | |
| Credential Guard / tamper protection on workstation | `[ enabled / disabled ]` | |
| EDR detected extraction tooling | `[ yes / no ]` | `<alert details>` |

### Detection performance
- KQL queries that surfaced this: `<list>`
- Endpoint alerts (FortiEDR / Defender for Endpoint): `<list>`
- Time-to-detect: `<minutes>`

### Recommended remediation
1.
2.

---

## Aggregate Control Effectiveness Matrix

| Control | OAuth Consent | Device Code | AitM | Endpoint Theft |
|---|---|---|---|---|
| User consent restriction | `__` | n/a | n/a | n/a |
| CA Authentication Flows (device code block) | n/a | `__` | n/a | n/a |
| Token Protection (native apps) | n/a | n/a | `__` | `__` |
| Token Protection (browser) | n/a | n/a | **N/A — unsupported by Microsoft today** | n/a |
| CAE strict location | partial | `__` | `__` | `__` |
| Compliant device CA | n/a | `__` | `__` | `__` |
| Phishing-resistant MFA | n/a | n/a | `__` | n/a |
| Defender Attack Disruption | `__` | `__` | `__` | `__` |
| EDR on endpoint | n/a | n/a | n/a | `__` |
| AppGate network filtering | n/a | n/a | partial | n/a |

Cells: `effective` / `ineffective` / `partial` / `not configured` / `n/a`

---

## Detection Performance Summary

| Vector | Surfaced by KQL? | Time-to-detect (min) | Alert(s) fired | Source |
|---|---|---|---|---|
| OAuth consent | `__` | `__` | `__` | `__` |
| Device code | `__` | `__` | `__` | `__` |
| AitM cookie capture | `__` | `__` | `__` | `__` |
| AitM cookie replay | `__` | `__` | `__` | `__` |
| PRT theft | `__` | `__` | `__` | `__` |
| Cookie theft (endpoint) | `__` | `__` | `__` | `__` |

---

## Prioritized Remediation Plan

Ordered by impact-per-effort. Each item links to specific findings above.

| # | Action | Addresses | Effort | Owner | Target date |
|---|---|---|---|---|---|
| 1 | `<e.g., Enforce phishing-resistant MFA for all users via Auth Strength CA>` | Vector 3, partial Vector 4 | M | | |
| 2 | `<e.g., Lock down user consent to verified publishers only>` | Vector 1 | S | | |
| 3 | `<e.g., Block device code flow via CA Auth Flows policy>` | Vector 2 | S | | |
| 4 | `<e.g., Roll out compliant device requirement to M365 cloud apps>` | Vectors 3, 4 | L | | |
| 5 | `<e.g., Enable CAE strict location after egress IP audit>` | Vectors 2, 3, 4 | M | | |
| 6 | `<e.g., Deploy Token Protection CA for Outlook/Teams desktop>` | Vector 4 (native) | M | | |
| 7 | `<e.g., Tune KQL detections from detection-pack.kql into Sentinel analytic rules>` | Detection gaps | M | | |

---

## Appendix A — IOCs from this test (for blue team tuning)

- Attacker IPs: `<list>`
- Attacker domains: `<list>`
- Test user UPNs: `<list>`
- Phishing message subjects sent: `<list>`
- App registration IDs (consent test): `<list>`

## Appendix B — Validation queries

After remediation rollout, re-run each KQL query from `05-detection/detection-pack.kql` and re-execute each vector to confirm the gap is closed. Record before/after timestamps.
