#!/bin/bash
# tmux-workspace.sh — Park 워크플로우용 tmux 멀티 세션 런처
# 용도: SSH 접속 후 한 번에 작업 환경 구성
# 실행: bash scripts/tmux-workspace.sh [preset]
#
# Presets:
#   default  — claude(audio) + claude(image) + bash
#   audio    — parksy-audio 집중 모드
#   batch    — 배치 작업 3개 창
#   monitor  — 모니터링 (htop + logs + bot)

set -e

SESSION_NAME="${2:-work}"
PRESET="${1:-default}"

# D: 드라이브 경로 (WSL / Git Bash 자동 감지)
if [ -d "/mnt/d" ]; then
    D_DRIVE="/mnt/d"
elif [ -d "/d" ]; then
    D_DRIVE="/d"
else
    D_DRIVE="$HOME"
    echo "[WARN] D: 드라이브 못 찾음. 홈 디렉토리 사용."
fi

AUDIO_DIR="$D_DRIVE/PARKSY/parksy-audio"
IMAGE_DIR="$D_DRIVE/parksy-image"
APK_DIR="$D_DRIVE/1_GITHUB/dtslib-apk-lab"
LOCALPC_DIR="$D_DRIVE/PARKSY/dtslib-localpc"

# 이미 세션이 있으면 attach
if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
    echo "기존 세션 '$SESSION_NAME'에 연결..."
    tmux attach -t "$SESSION_NAME"
    exit 0
fi

case "$PRESET" in
    default)
        echo "=== default 워크스페이스 ==="
        tmux new-session -d -s "$SESSION_NAME" -n "audio" -c "$AUDIO_DIR"
        tmux send-keys -t "$SESSION_NAME:audio" "claude" C-m

        tmux new-window -t "$SESSION_NAME" -n "image" -c "$IMAGE_DIR"
        tmux send-keys -t "$SESSION_NAME:image" "claude" C-m

        tmux new-window -t "$SESSION_NAME" -n "bash" -c "$LOCALPC_DIR"

        tmux select-window -t "$SESSION_NAME:audio"
        ;;

    audio)
        echo "=== parksy-audio 집중 모드 ==="
        tmux new-session -d -s "$SESSION_NAME" -n "claude" -c "$AUDIO_DIR"
        tmux send-keys -t "$SESSION_NAME:claude" "claude" C-m

        tmux new-window -t "$SESSION_NAME" -n "files" -c "$AUDIO_DIR"
        tmux send-keys -t "$SESSION_NAME:files" "ls -la" C-m

        tmux new-window -t "$SESSION_NAME" -n "tmp" -c "$D_DRIVE/tmp"

        tmux select-window -t "$SESSION_NAME:claude"
        ;;

    batch)
        echo "=== 배치 작업 모드 ==="
        tmux new-session -d -s "$SESSION_NAME" -n "batch1" -c "$D_DRIVE/tmp"
        tmux new-window -t "$SESSION_NAME" -n "batch2" -c "$D_DRIVE/tmp"
        tmux new-window -t "$SESSION_NAME" -n "batch3" -c "$D_DRIVE/tmp"
        tmux new-window -t "$SESSION_NAME" -n "monitor"
        tmux send-keys -t "$SESSION_NAME:monitor" "htop 2>/dev/null || top" C-m

        tmux select-window -t "$SESSION_NAME:batch1"
        ;;

    monitor)
        echo "=== 모니터링 모드 ==="
        tmux new-session -d -s "$SESSION_NAME" -n "htop"
        tmux send-keys -t "$SESSION_NAME:htop" "htop 2>/dev/null || top" C-m

        tmux new-window -t "$SESSION_NAME" -n "logs" -c "$LOCALPC_DIR"
        tmux send-keys -t "$SESSION_NAME:logs" "tail -f ~/telegram-bot/bot.log 2>/dev/null || echo 'Bot log 없음'" C-m

        tmux new-window -t "$SESSION_NAME" -n "git" -c "$D_DRIVE/1_GITHUB"
        tmux send-keys -t "$SESSION_NAME:git" "for d in */; do echo -n \"\$d: \"; cd \"\$d\" && git status -s | wc -l; cd ..; done" C-m

        tmux select-window -t "$SESSION_NAME:htop"
        ;;

    *)
        echo "사용법: bash tmux-workspace.sh [preset] [session-name]"
        echo ""
        echo "Presets:"
        echo "  default  — claude(audio) + claude(image) + bash"
        echo "  audio    — parksy-audio 집중 모드"
        echo "  batch    — 배치 작업 3개 창"
        echo "  monitor  — 모니터링 (htop + logs + git)"
        exit 1
        ;;
esac

echo "세션 '$SESSION_NAME' 생성 완료 (preset: $PRESET)"
echo "연결 중..."
tmux attach -t "$SESSION_NAME"
