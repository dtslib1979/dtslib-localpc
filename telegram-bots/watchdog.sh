#!/bin/bash
# WSL 서비스 워치독
# SSH, 텔레그램 봇 2개, Tailscale 감시 + Claude 인증 자동 갱신
#
# 봇 구조 (2봇 체제):
#   @parksy_bridge_bot  → parksy-image/tools/telegram-bridge/bot.py  (이미지+Claude)
#   @parksy_bridges_bot → parksy-audio/local-agent/bot.py             (오디오+Claude)

LOG=/home/dtsli/server.log
CREDS_WSL=/home/dtsli/.claude/.credentials.json
CREDS_WIN=/mnt/c/Users/dtsli/.claude/.credentials.json

# ── 텔레그램 알림 (@parksy_bridge_bot 재활용) ──
TG_BOT_TOKEN="8621929617:AAH-XpVJ4PKVJV8m9-qB2aLupMHO0nYfZLQ"
TG_CHAT_ID="6858098283"
TG_COOLDOWN=3600   # 같은 이벤트 1시간 내 중복 억제 (스팸 방지)
TG_STATE_DIR=/home/dtsli/.watchdog-state
mkdir -p "$TG_STATE_DIR"

notify_telegram() {
    local event="$1"
    local msg="$2"
    local state_file="$TG_STATE_DIR/${event//[^a-zA-Z0-9_]/_}"
    local now=$(date +%s)
    local last=0
    [ -f "$state_file" ] && last=$(cat "$state_file" 2>/dev/null || echo 0)
    if [ $((now - last)) -lt "$TG_COOLDOWN" ]; then
        return 0
    fi
    echo "$now" > "$state_file"
    curl -s -m 10 -X POST "https://api.telegram.org/bot${TG_BOT_TOKEN}/sendMessage" \
        --data-urlencode "chat_id=${TG_CHAT_ID}" \
        --data-urlencode "text=🤖 WATCHDOG: ${msg}" > /dev/null 2>&1
}

log_restart() {
    echo "[$(date)] $1 restarted" >> "$LOG"
    notify_telegram "$1" "$1 재기동 ($(hostname) $(date '+%m-%d %H:%M'))"
}

# watchdog 자체 기동 알림은 제거 (박씨 옵션 3, 2026-04-20)
# 대신 wsl-server-init.sh 마지막에 "부팅 복구 완료" 1회 전송
# watchdog 수동 재기동 시 알림 안 가도록 조용히 시작

# Claude credentials 유효성 체크 + 자동 갱신
refresh_claude_creds() {
    local now_ms=$(python3 -c "import time; print(int(time.time() * 1000))")
    local expires_ms=0

    if [ -f "$CREDS_WSL" ]; then
        expires_ms=$(python3 -c "
import json
try:
    d = json.load(open('$CREDS_WSL'))
    print(d.get('claudeAiOauth', {}).get('expiresAt', 0))
except:
    print(0)
")
    fi

    # 만료까지 1시간(3600000ms) 미만이면 Windows에서 동기화
    local threshold=$((now_ms + 3600000))
    if [ "$expires_ms" -lt "$threshold" ]; then
        if [ -f "$CREDS_WIN" ]; then
            cp "$CREDS_WIN" "$CREDS_WSL"
            chmod 600 "$CREDS_WSL"
            echo "[$(date)] Claude credentials synced from Windows" >> "$LOG"
        fi
    fi
}

while true; do
    # Claude credentials 갱신 체크 (매 루프)
    refresh_claude_creds

    # SSH 감시
    pgrep -x sshd > /dev/null || {
        sudo service ssh start
        log_restart "sshd"
    }

    # 이미지 봇 감시 (@parksy_bridge_bot — 이미지+Claude 통합)
    BOT_IMAGE=/mnt/d/parksy-image/tools/telegram-bridge/bot.py
    if [ -f "$BOT_IMAGE" ]; then
        pgrep -f "telegram-bridge/bot.py" > /dev/null || {
            tmux send-keys -t tg-image:0 C-c 2>/dev/null
            sleep 1
            tmux send-keys -t tg-image:0 "python3 $BOT_IMAGE" Enter 2>/dev/null
            log_restart "image bot (parksy-image)"
        }
    fi

    # 오디오 봇 감시 (@parksy_bridges_bot — 오디오+Claude 통합)
    BOT_AUDIO=/mnt/d/PARKSY/parksy-audio/local-agent/bot.py
    if [ -f "$BOT_AUDIO" ]; then
        pgrep -f "local-agent/bot.py" > /dev/null || {
            tmux send-keys -t tg-audio:0 C-c 2>/dev/null
            sleep 1
            tmux send-keys -t tg-audio:0 "python3 $BOT_AUDIO" Enter 2>/dev/null
            log_restart "audio bot (parksy-audio)"
        }
    fi

    # Tailscale 감시
    if ! pgrep -x tailscaled > /dev/null 2>&1; then
        sudo tailscaled --state=/var/lib/tailscale/tailscaled.state --socket=/run/tailscale/tailscaled.sock --port=41641 > /dev/null 2>&1 &
        sleep 3
        sudo tailscale up --accept-routes --accept-dns=false > /dev/null 2>&1
        log_restart "tailscaled"
    fi

    sleep 60
done
