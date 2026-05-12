# M365 Token Theft Red Team - Phase 2 Tooling

Companion to `M365-Token-Theft-RedTeam-Methodology.md`.

**Scope:** Testing harnesses for your dev tenant. Each subdirectory corresponds to a vector from the methodology.

**Design principle:** Where mature public red-team tools exist (Evilginx, ROADtools, TokenTacticsV2, AADInternals, GraphRunner), this kit wraps and orchestrates them rather than reimplementing. You'll get bug fixes and updates from those projects; the value here is the test framework, detection queries, and reporting structure.

## Layout

```
01-oauth-consent/    OAuth illicit consent grant test harness
02-device-code/      Device code flow phishing tester
03-evilginx/         Evilginx3 deployment + test runner
04-endpoint/         PRT theft + browser cookie extraction wrappers
05-detection/        KQL detection pack (Sentinel / Defender XDR)
findings-report-template.md   Fill-in-the-blank results doc
```

## Execution order

Per methodology - low impact / low setup to high:
1. `01-oauth-consent/` — no infra, ~30 min to set up
2. `02-device-code/` — no infra, ~5 min
3. `03-evilginx/` — needs cloud VM + domain
4. `04-endpoint/` — needs victim VM access

## Required external tooling (install on attacker box)

| Tool | Purpose | Install |
|---|---|---|
| Python 3.10+ | OAuth/device-code scripts | apt/dnf |
| `requests`, `flask` | Python deps | `pip install -r requirements.txt` |
| ROADtools / roadtx | PRT manipulation | `pip install roadtools roadrecon roadtx` |
| TokenTacticsV2 | Token enumeration | `Install-Module TokenTacticsV2` (PS) or git clone |
| AADInternals | PRT extraction on victim | `Install-Module AADInternals` |
| Evilginx3 | AitM proxy | See `03-evilginx/deploy.sh` |

## Safety/legal notes

- Run only against the dev tenant you control.
- Microsoft's pen test rules of engagement permit this on tenants you own; no prior approval needed for phishing simulation of your own users.
- Don't reuse attacker infrastructure for anything else. Burn the VMs after testing.
- Do not run any of this against production users or third-party tenants.
