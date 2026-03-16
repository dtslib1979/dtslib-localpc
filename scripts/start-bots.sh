#!/bin/bash
# Parksy 텔레그램 봇 런처 v2.0
# @parksy_bridge_bot  (tg-image) + @parksy_bridges_bot (tg-audio)

IMAGE_BOT="/mnt/d/parksy-image/tools/telegram-bridge/bot.py"
AUDIO_BOT="/mnt/d/PARKSY/parksy-audio/local-agent/bot.py"

start_session() {
    local name=$1
    local script=$2
    if tmux has-session -t "$name" 2>/dev/null; then
        echo "[$name] 기존 세션 종료 중..."
        tmux kill-session -t "$name"
        sleep 1
    fi
    echo "[$name] 시작: $script"
    tmux new-session -d -s "$name" "python3 $script; echo '=== 종료됨 ==='; read"
    sleep 0.5
    if tmux has-session -t "$name" 2>/dev/null; then
        echo "[$name] ✅ 실행 중"
    else
        echo "[$name] ❌ 시작 실패"
    fi
}

echo "=== Parksy Bot Launcher v2.0 ==="
start_session "tg-image" "$IMAGE_BOT"
start_session "tg-audio" "$AUDIO_BOT"

echo ""
echo "세션 확인: tmux ls"
echo "로그 확인:"
echo "  tmux attach -t tg-image"
echo "  tmux attach -t tg-audio"
