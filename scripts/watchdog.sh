#!/bin/bash
# WSL 서비스 워치독
# SSH, 브릿지, Claude 봇, Tailscale 감시 + Claude 인증 자동 갱신

LOG=/home/dtsli/server.log
CREDS_WSL=/home/dtsli/.claude/.credentials.json
CREDS_WIN=/mnt/c/Users/dtsli/.claude/.credentials.json

log_restart() {
    echo "[$(date)] $1 restarted" >> "$LOG"
}

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

    # 이미지 브릿지 감시
    pgrep -f image_downloader.py > /dev/null || {
        tmux send-keys -t tg-image:bridge C-c 2>/dev/null
        sleep 1
        tmux send-keys -t tg-image:bridge "cd /home/dtsli/dtslib-localpc/telegram-bots && python3 image_downloader.py" Enter 2>/dev/null
        log_restart "image bridge"
    }

    # 오디오 브릿지 감시
    pgrep -f audio_bridge.py > /dev/null || {
        tmux send-keys -t tg-audio:bridge C-c 2>/dev/null
        sleep 1
        tmux send-keys -t tg-audio:bridge "cd /home/dtsli/dtslib-localpc/telegram-bots && python3 audio_bridge.py" Enter 2>/dev/null
        log_restart "audio bridge"
    }

    # 이미지 Claude 봇 감시
    pgrep -f "claude_image_config" > /dev/null || {
        tmux send-keys -t tg-image:work C-c 2>/dev/null
        sleep 1
        tmux send-keys -t tg-image:work "cd /home/dtsli/dtslib-localpc/telegram-bots && python3 telegram_claude_bot.py --config claude_image_config.json" Enter 2>/dev/null
        log_restart "image claude bot"
    }

    # 오디오 Claude 봇 감시
    pgrep -f "claude_audio_config" > /dev/null || {
        tmux send-keys -t tg-audio:work C-c 2>/dev/null
        sleep 1
        tmux send-keys -t tg-audio:work "cd /home/dtsli/dtslib-localpc/telegram-bots && python3 telegram_claude_bot.py --config claude_audio_config.json" Enter 2>/dev/null
        log_restart "audio claude bot"
    }

    # Tailscale 감시
    if ! pgrep -x tailscaled > /dev/null 2>&1; then
        sudo tailscaled --state=/var/lib/tailscale/tailscaled.state --socket=/run/tailscale/tailscaled.sock --port=41641 > /dev/null 2>&1 &
        sleep 3
        sudo tailscale up --accept-routes --accept-dns=false > /dev/null 2>&1
        log_restart "tailscaled"
    fi

    sleep 60
done
