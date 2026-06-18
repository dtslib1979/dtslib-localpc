#!/usr/bin/env bash
# triage.sh — L3 응급진단 (읽기전용)
# 실행환경: MSYS2 bash (WSL 비의존)
# Termius "Phone to WinPC" Command:
#   C:\msys64\usr\bin\bash.exe --login -i -c "bash /c/Users/dtsli/triage.sh; exec bash --login -i"

echo "=== L3 Triage [$(date '+%Y-%m-%d %H:%M')] ==="

wsl_ok() {
  timeout 5 wsl.exe -d Ubuntu -u dtsli -- echo ok 2>/dev/null
  return $?
}

echo ""
echo "--- WSL 상태 ---"
if wsl_ok >/dev/null 2>&1; then
  echo "  ✅ WSL 응답함"
  echo ""
  echo "--- WSL healthcheck ---"
  wsl.exe -d Ubuntu -u dtsli -- bash -c '
    echo "  tmux: $(tmux ls 2>/dev/null | wc -l) sessions"
    echo "  autossh: $(pgrep -f "autossh.*2222" | wc -l) instance(s)"
    echo "  bots: $(ps aux | grep bot.py | grep -v grep | wc -l) running"
    echo "  tailscale: $(tailscale status 2>/dev/null | grep -c active) active"
    echo "  disk: $(df -h /mnt/c | awk "NR==2{print \$3 \"/\" \$2}")"
  ' 2>&1
else
  echo "  ❌ WSL 무응답"
fi

echo ""
echo "--- Windows native ---"
echo "  sshd: $(powershell.exe -Command "Get-Process sshd -EA SilentlyContinue | Measure-Object | Select -ExpandProperty Count" 2>/dev/null || echo '?') processes"
echo "  port 2222: $(powershell.exe -Command "Get-NetTCPConnection -LocalPort 2222 -State Listen -EA SilentlyContinue | Measure-Object | Select -ExpandProperty Count" 2>/dev/null || echo '?') listener(s)"

echo ""
echo "--- Canon (termux-bridge repo) ---"
if [ -d /c/Users/dtsli/termux-bridge ]; then
  cd /c/Users/dtsli/termux-bridge 2>/dev/null && echo "  repo: present, $(git log --oneline -1 2>/dev/null || echo 'no commits')"
else
  echo "  repo: not cloned on C:"
fi

echo ""
echo "=== 진단완료 ==="
echo "※ L3 읽기전용 — 직접 수정 금지. 필요시 박씨 승인 → repo commit → push"
