#!/bin/bash
# ============================================
# WSL Claude Code Server - Auto Init Script
# 4세션 병렬 구조: claude-main / tg-image / tg-audio / watchdog
# ============================================

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
if ! pgrep -x tailscaled > /dev/null; then
    sudo tailscaled --state=/var/lib/tailscale/tailscaled.state &>/dev/null &
    sleep 2
    sudo tailscale up --accept-routes --accept-dns=false --reset 2>/dev/null &
    log 'Tailscale started'
else
    log 'Tailscale already running'
fi

# ── 3. claude-main: 메인 작업 세션 (SSH → tmux attach 용) ──
tmux has-session -t claude-main 2>/dev/null || {
    tmux new-session -d -s claude-main -n work
    tmux send-keys -t claude-main:work 'source ~/.bashrc && cd /mnt/d' Enter
    log "tmux 'claude-main' created"
}

# ── 4. tg-image: 이미지 채널 전용 세션 ──
tmux has-session -t tg-image 2>/dev/null || {
    tmux new-session -d -s tg-image -n bridge
    tmux send-keys -t tg-image:bridge 'source ~/.bashrc && cd /home/dtsli/telegram-bridges && python3 image_downloader.py' Enter
    tmux new-window -t tg-image -n work
    tmux send-keys -t tg-image:work 'source ~/.bashrc && cd /home/dtsli/telegram-bridges && python3 telegram_claude_bot.py --config claude_image_config.json' Enter
    log "tmux 'tg-image' created"
}

# ── 5. tg-audio: 오디오 채널 전용 세션 ──
tmux has-session -t tg-audio 2>/dev/null || {
    tmux new-session -d -s tg-audio -n bridge
    tmux send-keys -t tg-audio:bridge 'source ~/.bashrc && cd /home/dtsli/telegram-bridges && python3 audio_bridge.py' Enter
    tmux new-window -t tg-audio -n work
    tmux send-keys -t tg-audio:work 'source ~/.bashrc && cd /home/dtsli/telegram-bridges && python3 telegram_claude_bot.py --config claude_audio_config.json' Enter
    log "tmux 'tg-audio' created"
}

# ── 6. watchdog ──
tmux kill-session -t watchdog 2>/dev/null
tmux new-session -d -s watchdog -n monitor
tmux send-keys -t watchdog:monitor 'source ~/.bashrc && bash /home/dtsli/telegram-bridges/watchdog.sh' Enter
log 'Watchdog started'

WSL_IP=$(hostname -I | awk '{print $1}')
TS_IP=$(tailscale ip 2>/dev/null | head -1)
log "WSL IP: $WSL_IP | Tailscale IP: $TS_IP"
log '=== Server Init Complete ==='

echo ''
echo '╔══════════════════════════════════════════╗'
echo '║   WSL Claude Code Server Ready           ║'
echo '╠══════════════════════════════════════════╣'
printf "║ WSL IP:       %-28s║\n" "$WSL_IP"
printf "║ Tailscale IP: %-28s║\n" "$TS_IP"
echo '╠══════════════════════════════════════════╣'
echo '║ 세션 구조 (4 병렬):                      ║'
echo '║  claude-main  → SSH 접속 후 claude 실행  ║'
echo '║  tg-image     → 이미지 브릿지+Claude봇   ║'
echo '║  tg-audio     → 오디오 브릿지+Claude봇   ║'
echo '║  watchdog     → 서비스 감시              ║'
echo '╚══════════════════════════════════════════╝'
tmux list-sessions
