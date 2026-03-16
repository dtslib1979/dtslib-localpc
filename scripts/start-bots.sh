#!/bin/bash
# start-bots.sh — 텔레그램 봇 tmux 세션 일괄 시작
#
# 구조:
#   tmux tg-image → parksy-image 봇 (이미지 수신 + 명령어)
#   tmux tg-audio → parksy-audio 봇 (오디오 파이프라인 제어)
#
# 사용:
#   bash scripts/start-bots.sh
#   bash scripts/start-bots.sh stop   # 세션 종료
#   bash scripts/start-bots.sh status # 세션 상태 확인

ACTION="${1:-start}"

# WSL 경로 설정
if grep -qi microsoft /proc/version 2>/dev/null; then
  IMAGE_PATH="/mnt/d/parksy-image"
  AUDIO_PATH="/mnt/d/PARKSY/parksy-audio"
else
  IMAGE_PATH="$HOME/parksy-image"
  AUDIO_PATH="$HOME/parksy-audio"
fi

case "$ACTION" in
  stop)
    echo "🛑 봇 세션 종료..."
    tmux kill-session -t tg-image 2>/dev/null && echo "  ✅ tg-image 종료"
    tmux kill-session -t tg-audio 2>/dev/null && echo "  ✅ tg-audio 종료"
    ;;
  status)
    echo "📊 봇 세션 상태:"
    tmux ls 2>/dev/null | grep -E "tg-image|tg-audio" || echo "  실행 중인 봇 없음"
    ;;
  start|*)
    echo "🤖 텔레그램 봇 시작..."
    echo ""

    # 기존 세션 정리
    tmux kill-session -t tg-image 2>/dev/null
    tmux kill-session -t tg-audio 2>/dev/null

    # parksy-image 봇
    BOT_IMAGE="$IMAGE_PATH/tools/telegram-bridge/bot.py"
    if [ -f "$BOT_IMAGE" ]; then
      tmux new-session -d -s tg-image \
        "cd  && pip install requests -q && python3 tools/telegram-bridge/bot.py 2>&1 | tee /tmp/tg-image.log"
      echo "✅ tg-image 시작"
      echo "   접속: tmux attach -t tg-image"
      echo "   로그: tail -f /tmp/tg-image.log"
    else
      echo "❌ tg-image: bot.py 없음 ($IMAGE_PATH)"
      echo "   git clone https://github.com/dtslib1979/parksy-image $IMAGE_PATH"
    fi

    echo ""

    # parksy-audio 봇
    BOT_AUDIO="$AUDIO_PATH/local-agent/bot.py"
    if [ -f "$BOT_AUDIO" ]; then
      tmux new-session -d -s tg-audio \
        "cd  && pip install requests -q && python3 local-agent/bot.py 2>&1 | tee /tmp/tg-audio.log"
      echo "✅ tg-audio 시작"
      echo "   접속: tmux attach -t tg-audio"
      echo "   로그: tail -f /tmp/tg-audio.log"
    else
      echo "❌ tg-audio: bot.py 없음 ($AUDIO_PATH)"
      echo "   git clone https://github.com/dtslib1979/parksy-audio $AUDIO_PATH"
    fi

    echo ""
    echo "세션 목록: tmux ls"
    ;;
esac

