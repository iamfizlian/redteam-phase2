#!/bin/bash
# Evilginx3 deployment for AitM control validation testing
# Target: Debian 12 / Ubuntu 22.04+ cloud VM (DigitalOcean, etc.)
#
# Deploys upstream Evilginx2/3 from github.com/kgretzky/evilginx2.
# Does NOT include any phishlets — those are managed separately.
# Stock o365 phishlet in upstream is intentionally outdated.

set -euo pipefail

if [ "$EUID" -ne 0 ]; then echo "Run as root"; exit 1; fi

echo "[*] Installing dependencies..."
apt-get update -qq
apt-get install -y -qq golang-go git make build-essential ufw ca-certificates

echo "[*] Cloning Evilginx upstream..."
cd /opt
if [ ! -d evilginx2 ]; then
    git clone https://github.com/kgretzky/evilginx2.git
fi
cd evilginx2

echo "[*] Building..."
make

echo "[*] Setting up firewall..."
ufw --force reset >/dev/null
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp comment "ssh"
ufw allow 80/tcp comment "evilginx http (ACME challenge)"
ufw allow 443/tcp comment "evilginx https"
ufw allow 53 comment "evilginx dns"
ufw --force enable

echo "[*] Done. Binary: /opt/evilginx2/bin/evilginx"
echo ""
echo "==============================================================="
echo "NEXT STEPS"
echo "==============================================================="
echo ""
echo "1. Point DNS for your test phishing domain (both apex and *)"
echo "   at this VM's public IP. Wait for propagation."
echo ""
echo "2. Run interactively:"
echo "     cd /opt/evilginx2 && ./bin/evilginx -p ./phishlets/"
echo ""
echo "3. Inside Evilginx shell:"
echo "     config domain <your-phish-domain>"
echo "     config ipv4 external <vm-public-ip>"
echo "     phishlets hostname o365 <your-phish-domain>"
echo "     phishlets enable o365"
echo "     lures create o365"
echo "     lures get-url 0"
echo ""
echo "PHISHLET NOTE:"
echo "  The upstream o365 phishlet is intentionally outdated to deter"
echo "  abuse. Working phishlets are maintained in the community;"
echo "  Kuba Gretzky's Evilginx Mastery course covers building one"
echo "  legitimately for red team use. This deployment script does not"
echo "  bundle a working phishlet."
echo ""
echo "POST-TEST CLEANUP:"
echo "  - Destroy the VM (don't reuse infrastructure)"
echo "  - Release the test phishing domain"
echo "  - Document all attacker IPs/domains for blue team forensic IOC tuning"
