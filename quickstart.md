Installation & Use
Step 1 — Get the kit on your machine
Download redteam-phase2.zip from this chat, then:
bashunzip redteam-phase2.zip
cd redteam-phase2
Or on Windows: right-click → Extract All.
Step 2 — Pick your starting point
You don't install the kit itself — it's documentation + one shell script + one KQL file. The "install" is per-vector, only when you're ready to run that vector. Order matters:
WhenWhat to doFirst (no infrastructure needed)Deploy the KQL detection pack to see your current baselineThenVector 1 (OAuth consent) — lowest setup costThenVector 2 (device code) — no infraThenVector 3 (Evilginx) — needs cloud VM + domainThenVector 4 (endpoint theft) — needs victim VM access

Step 3 — Deploy the detection pack first (do this before any attacks)
This is the highest-value file and runs independently. Open 05-detection/detection-pack.kql.
Option A — Defender XDR (easiest):

Go to https://security.microsoft.com → Hunting → Advanced hunting
Copy a single query (everything between two // === section dividers) into the query box
Run it. Tune as needed. Save as a custom detection rule if you want it to alert.

Option B — Sentinel:

Sentinel workspace → Hunting (or Analytics for rules)
New query → paste a single query block → Save
For continuous alerting: Analytics → Create → Scheduled query rule → paste KQL

Run all the queries once now to establish baseline. The ones you'll care about most for testing: 1.1 (consent grants), 2.1 (device code auths), 3.2 (Token Protection enforcement).

Step 4 — Run Vector 1 (OAuth consent)
Open 01-oauth-consent/README.md and follow it. Summary of what you'll do:

Spin up a separate Entra tenant (free dev tenant from https://developer.microsoft.com/microsoft-365/dev-program). This is your "attacker tenant."
In that tenant, register a multitenant app with Mail.Read, Files.Read.All, User.Read, offline_access delegated permissions. Save the client ID + secret.
Install GraphRunner on your attacker box (any machine — Linux or Windows):

powershell   git clone https://github.com/dafthack/GraphRunner.git
   cd GraphRunner
   Import-Module .\GraphRunner.ps1

Build the consent URL (template in the README), send it to your victim test user in your dev tenant.
Victim clicks Accept → you get the auth code in the redirect URL → exchange it for tokens (curl/Invoke-RestMethod command in the README).
Run the persistence tests in the README's matrix (refresh after 24h, after password reset, etc.).
Check the detection pack queries to see what fired.
Fill in the relevant section of findings-report-template.md.


Step 5 — Run Vector 2 (device code)
Open 02-device-code/README.md. Summary:

Install TokenTacticsV2 on your attacker box:

powershell   Install-Module TokenTacticsV2 -Scope CurrentUser

Run Invoke-DeviceCodeFlow -Client AzurePowerShell -Resource MSGraph. It prints a user code.
Send the user code to your victim with a pretext like "Teams needs reauthorization, enter this code at microsoft.com/devicelogin".
Victim enters code → TokenTacticsV2 captures tokens.
Verify with a Graph API call.
Check detection queries (especially 2.1, 2.2, 2.3).
Fill in findings report.


Step 6 — Run Vector 3 (Evilginx AitM)
Open 03-evilginx/README.md. This is the heaviest one.

Spin up a cloud VM — DigitalOcean droplet, Debian 12, 2 vCPU / 4GB. Get the public IP.
Register a phishing domain — Namecheap, Porkbun, whatever. Something that looks like Microsoft.
Point DNS apex + wildcard * at the VM's public IP. Wait for propagation.
SCP 03-evilginx/deploy.sh to the VM, then:

bash   ssh root@<vm-ip>
   sudo bash deploy.sh

Get a working o365 phishlet (the script doesn't ship one — see README for why). Either build one from Evilginx docs or take the Evilginx Mastery course.
Run Evilginx, configure it (commands in deploy.sh output), enable the phishlet, generate a lure URL.
Send lure to victim test user → victim authenticates through your proxy → Evilginx captures session cookie.
Run the full replay matrix in the README (this is the actual test): replay against web outlook from attacker box, against Teams desktop, against victim04 (FIDO2 user — should fail at MFA), etc.
After: destroy the VM, release the domain.


Step 7 — Run Vector 4 (endpoint theft)
Open 04-endpoint/README.md. You need access to a victim VM (an Entra-joined Win11 box).
4a — PRT theft:

On victim VM as logged-in user:

powershell   Install-Module AADInternals -Scope CurrentUser
   $prtKeys = Get-AADIntUserPRTKeys
   $prtKeys | ConvertTo-Json | Out-File ".\prt.json"

Copy prt.json to attacker box, install roadtx (pip install roadtools roadrecon roadtx), replay per README.

4b — Browser cookie theft:

Download HackBrowserData from its GitHub releases onto victim VM.
Run it to dump cookies.
Import ESTSAUTH cookies into Chrome on attacker box via Cookie Editor extension, browse to outlook.office.com.

4c — MSAL cache theft:

Use SharpDPAPI on victim box to decrypt the token caches.
Replay refresh tokens via roadtx or TokenTacticsV2.

Check detection queries (especially 4.1 and 4.2) — these are the endpoint-side detections.

Step 8 — Document everything in the findings report
Open findings-report-template.md. Fill in as you go (don't wait until the end). The Control Effectiveness Matrix at the bottom is the executive deliverable.

Tooling install summary (all in one place)
On your attacker box (Linux or Windows, your choice):
bash# Python tools
pip install roadtools roadrecon roadtx

# PowerShell tools (cross-platform PS 7+, or Windows PS 5.1)
Install-Module TokenTacticsV2 -Scope CurrentUser
Install-Module AADInternals -Scope CurrentUser
Install-Module Microsoft.Graph -Scope CurrentUser

# GraphRunner (git clone, not a module)
git clone https://github.com/dafthack/GraphRunner.git

# HackBrowserData — download binary from github.com/moonD4rk/HackBrowserData/releases
# SharpDPAPI — clone from github.com/GhostPack/SharpDPAPI, build in Visual Studio
# Evilginx — handled by deploy.sh on the cloud VM
Common pitfalls

Don't run this against production. Use a dedicated dev tenant.
Don't reuse attacker infrastructure. Burn the VM and domain after testing.
Token Protection only works on native apps on Windows. Don't expect browser sessions to be protected — that's the gap the test is designed to prove.
CAE strict location only works if every legitimate egress IP is in your named locations. Test with a small pilot user first, or you'll lock people out.
Refresh tokens survive password resets. When remediating real compromises, you must explicitly revoke sessions (Revoke-MgUserSignInSession), not just reset the password.

Start with Step 3 (detection pack baseline) before anything else — it'll show you what your tenant already catches, and that informs how much you actually need to test.