# Termius Workspace — Environment Snapshot
# Source: canon-infra-plan + live healthcheck
# Run: source env.sh to verify current state

WSL_IP=$(powershell.exe -Command "wsl -d Ubuntu -u dtsli -- hostname -I 2>/dev/null" 2>/dev/null | awk '{print $1}')
TS_IP=$(powershell.exe -Command "wsl -d Ubuntu -u dtsli -- tailscale ip 2>/dev/null | head -1" 2>/dev/null)
WIN_IP=$(powershell.exe -Command "(Get-NetIPAddress -AddressFamily IPv4 | Where-Object IPAddress -like '100.*').IPAddress" 2>/dev/null)

echo "╔══════════════════════════════════════╗"
echo "║   Termius Workspace Healthcheck      ║"
echo "╚══════════════════════════════════════╝"
echo "Windows Tailscale : ${WIN_IP:-❌}"
echo "WSL Tailscale    : ${TS_IP:-❌}"
echo "WSL IP           : ${WSL_IP:-❌}"
echo ""

# WSL reverse tunnel
echo "--- WSL Reverse Tunnel ---"
powershell.exe -Command "Get-NetTCPConnection -LocalPort 2222 -State Listen 2>/dev/null | Select LocalAddress,State" 2>/dev/null

# WSL tmux sessions
echo ""
echo "--- WSL tmux Sessions ---"
powershell.exe -Command "wsl -d Ubuntu -u dtsli -- tmux ls 2>/dev/null" 2>/dev/null

# WSL bots
echo ""
echo "--- Telegram Bots ---"
powershell.exe -Command "wsl -d Ubuntu -u dtsli -- ps aux | grep bot.py | grep -v grep" 2>/dev/null

# Phone SSH
PHONE_IP=$(cat ~/.phone_ip 2>/dev/null || echo "unknown")
echo ""
echo "--- Phone Connectivity ($PHONE_IP) ---"
powershell.exe -Command "wsl -d Ubuntu -u dtsli -- ssh -p 8022 -o ConnectTimeout=3 -o StrictHostKeyChecking=no $PHONE_IP 'echo SSH OK' 2>&1" 2>/dev/null
