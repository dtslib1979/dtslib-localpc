#!/bin/bash
# ============================================
# WSL Claude Code Server - Auto Init Script
# 7세션 병렬 구조: 5-Lane + tg-image + tg-audio + watchdog
# ============================================

CLAUDE_BIN="/home/dtsli/.nvm/versions/node/v24.14.0/bin/claude"
[ ! -f "$CLAUDE_BIN" ] && CLAUDE_BIN="/usr/bin/claude"

LOG="/home/dtsli/server.log"
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" >> "$LOG"; }
log '=== Server Init Start ==='

# ── 0. D: Drive Mount ──
if [ ! -d /mnt/d/tmp ]; then
    sudo mount -t drvfs D: /mnt/d 2>/dev/null
    log 'D: drive mounted'
fi

# ── 1. SSH Server ──
if ! pgrep -x sshd > /dev/null; then
    sudo service ssh start
    log 'SSH started on port 2222'
else
    log 'SSH already running'
fi

# ── 2. Tailscale ──
sudo mkdir -p /var/run/tailscale
if ! pgrep -x tailscaled > /dev/null; then
    sudo tailscaled --state=/var/lib/tailscale/tailscaled.state --socket=/var/run/tailscale/tailscaled.sock &>/dev/null &
    sleep 4
    sudo tailscale up --accept-routes --accept-dns=false 2>/dev/null
    log 'Tailscale started'
else
    # 소켓 없으면 재시작
    if [ ! -S /var/run/tailscale/tailscaled.sock ]; then
        sudo kill $(pgrep -x tailscaled) 2>/dev/null
        sleep 2
        sudo tailscaled --state=/var/lib/tailscale/tailscaled.state --socket=/var/run/tailscale/tailscaled.sock &>/dev/null &
        sleep 4
        sudo tailscale up --accept-routes --accept-dns=false 2>/dev/null
        log 'Tailscale restarted (socket missing)'
    else
        log 'Tailscale already running'
    fi
fi

# ── 3. 5-Lane 세션 생성 (폰/탭 접속용) ──

# phone_claude: 폰 전용 Claude Code 세션
tmux has-session -t phone_claude 2>/dev/null || {
    tmux new-session -d -s phone_claude -n main
    tmux send-keys -t phone_claude:main "source ~/.bashrc && export PATH=/home/dtsli/.nvm/versions/node/v24.14.0/bin:\$PATH && cd /home/dtsli && $CLAUDE_BIN" Enter
    log "tmux 'phone_claude' created (claude auto-started)"
}

# tab_claude: 탭 전용 Claude Code 세션
tmux has-session -t tab_claude 2>/dev/null || {
    tmux new-session -d -s tab_claude -n main
    tmux send-keys -t tab_claude:main "source ~/.bashrc && export PATH=/home/dtsli/.nvm/versions/node/v24.14.0/bin:\$PATH && cd /home/dtsli && $CLAUDE_BIN" Enter
    log "tmux 'tab_claude' created (claude auto-started)"
}

# phone_aider: 폰 전용 aider 세션
tmux has-session -t phone_aider 2>/dev/null || {
    tmux new-session -d -s phone_aider -n main
    tmux send-keys -t phone_aider:main 'source ~/.bashrc && cd /home/dtsli' Enter
    log "tmux 'phone_aider' created"
}

# tab_aider: 탭 전용 aider 세션
tmux has-session -t tab_aider 2>/dev/null || {
    tmux new-session -d -s tab_aider -n main
    tmux send-keys -t tab_aider:main 'source ~/.bashrc && cd /home/dtsli' Enter
    log "tmux 'tab_aider' created"
}

# claude-main: 레거시 메인 세션 유지
tmux has-session -t claude-main 2>/dev/null || {
    tmux new-session -d -s claude-main -n work
    tmux send-keys -t claude-main:work 'source ~/.bashrc && cd /mnt/d' Enter
    log "tmux 'claude-main' created"
}

# ── 4. tg-image: 이미지 봇 (@parksy_bridge_bot) ──
tmux has-session -t tg-image 2>/dev/null || {
    tmux new-session -d -s tg-image -n image-bot
    tmux send-keys -t tg-image:0 'source ~/.bashrc && python3 /mnt/d/parksy-image/tools/telegram-bridge/bot.py' Enter
    log "tmux 'tg-image' created (@parksy_bridge_bot)"
}

# ── 5. tg-audio: 오디오 봇 (@parksy_bridges_bot) ──
tmux has-session -t tg-audio 2>/dev/null || {
    tmux new-session -d -s tg-audio -n audio-bot
    tmux send-keys -t tg-audio:0 'source ~/.bashrc && python3 /mnt/d/PARKSY/parksy-audio/local-agent/bot.py' Enter
    log "tmux 'tg-audio' created (@parksy_bridges_bot)"
}

# ── 6. watchdog ──
tmux kill-session -t watchdog 2>/dev/null
tmux new-session -d -s watchdog -n monitor
tmux send-keys -t watchdog:monitor 'source ~/.bashrc && bash /home/dtsli/dtslib-localpc/telegram-bots/watchdog.sh' Enter
log 'Watchdog started'

WSL_IP=$(hostname -I | awk '{print $1}')
TS_IP=$(tailscale ip 2>/dev/null | head -1)
log "WSL IP: $WSL_IP | Tailscale IP: $TS_IP"
log '=== Server Init Complete ==='

# ── 7. 부팅 복구 완료 알림 (박씨 폰 텔레그램, 2026-04-20 추가) ──
(
    sleep 2
    curl -s -m 10 -X POST "https://api.telegram.org/bot8621929617:AAH-XpVJ4PKVJV8m9-qB2aLupMHO0nYfZLQ/sendMessage" \
        --data-urlencode "chat_id=6858098283" \
        --data-urlencode "text=✅ PC 부팅 복구 완료
🕐 $(date '+%m-%d %H:%M')
🖥 $(hostname)
🌐 WSL IP: $WSL_IP
🔒 Tailscale: $TS_IP
🎛 5-Lane + 2봇 + watchdog 준비 완료" > /dev/null 2>&1
) &

echo ''
echo '╔══════════════════════════════════════════╗'
echo '║   WSL Claude Code Server Ready           ║'
echo '╠══════════════════════════════════════════╣'
printf "║ WSL IP:       %-28s║\n" "$WSL_IP"
printf "║ Tailscale IP: %-28s║\n" "$TS_IP"
echo '╠══════════════════════════════════════════╣'
echo '║ 세션 구조 (5-Lane + 봇):                 ║'
echo '║  phone_claude → 폰용 Claude Code        ║'
echo '║  tab_claude   → 탭용 Claude Code        ║'
echo '║  phone_aider  → 폰용 aider              ║'
echo '║  tab_aider    → 탭용 aider              ║'
echo '║  tg-image     → @parksy_bridge_bot      ║'
echo '║  tg-audio     → @parksy_bridges_bot     ║'
echo '║  watchdog     → 서비스 감시             ║'
echo '╚══════════════════════════════════════════╝'
tmux list-sessions
