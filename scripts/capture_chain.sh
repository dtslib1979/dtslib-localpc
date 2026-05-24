#!/bin/bash
# capture_chain.sh — 탭 캡처 파일 → MCP 체인 자동 트리거
#
# 사용법:
#   capture_chain.sh screenshot /mnt/d/태블릿_캡쳐/Screenshots/20260524/Screenshot_xxx.png
#   capture_chain.sh record     /mnt/d/태블릿_캡쳐/Recordings/20260524/Recording_xxx.mp4
#   capture_chain.sh sketch     /mnt/d/태블릿_캡쳐/Sketches/20260524/sketch_xxx_contour.png
#
# 각 유형별 MCP 체인:
#   screenshot → parksy-distributor TG 즉시 전송 (+ 선택적으로 parksy-actor 컴파일)
#   record     → parksy-distributor TG 전송 (영상 그대로)
#   sketch     → parksy-distributor TG 이미지 전송

set -e

TYPE="${1:-screenshot}"
FILE="${2:-}"
BOT_TOKEN="${PARKSY_BOT_TOKEN:-8621929617:AAH-XpVJ4PKVJV8m9-qB2aLupMHO0nYfZLQ}"
CHAT_ID="${PARKSY_CHAT_ID:-6858098283}"

if [ -z "$FILE" ] || [ ! -f "$FILE" ]; then
    echo "파일 없음: $FILE"
    exit 1
fi

FNAME=$(basename "$FILE")
TS=$(date '+%Y-%m-%d %H:%M:%S')

case "$TYPE" in
    screenshot)
        echo "[CHAIN] 스크린샷 → TG 전송: $FNAME"
        CAPTION="📸 탭 스크린샷 ($TS)"
        curl -s -X POST \
            "https://api.telegram.org/bot${BOT_TOKEN}/sendPhoto" \
            -F "chat_id=$CHAT_ID" \
            -F "photo=@${FILE}" \
            -F "caption=$CAPTION" \
            | python3 -c "import sys,json; r=json.load(sys.stdin); print('✅ TG OK' if r.get('ok') else f'❌ TG 실패: {r}')"
        ;;
    record)
        echo "[CHAIN] 화면녹화 → TG 전송: $FNAME"
        CAPTION="🎬 탭 화면녹화 ($TS)"
        # 영상 파일 크기 확인 (50MB 초과 시 경고)
        SIZE=$(stat -c%s "$FILE" 2>/dev/null || echo 0)
        if [ "$SIZE" -gt 52428800 ]; then
            echo "[WARN] 파일 크기 ${SIZE}B → TG 50MB 제한 초과, sendDocument 시도"
            curl -s -X POST \
                "https://api.telegram.org/bot${BOT_TOKEN}/sendDocument" \
                -F "chat_id=$CHAT_ID" \
                -F "document=@${FILE}" \
                -F "caption=$CAPTION" \
                | python3 -c "import sys,json; r=json.load(sys.stdin); print('✅ TG OK' if r.get('ok') else f'❌ TG 실패 (크기 제한): {r.get(\"description\",\"\")}')"
        else
            curl -s -X POST \
                "https://api.telegram.org/bot${BOT_TOKEN}/sendVideo" \
                -F "chat_id=$CHAT_ID" \
                -F "video=@${FILE}" \
                -F "caption=$CAPTION" \
                -F "supports_streaming=true" \
                | python3 -c "import sys,json; r=json.load(sys.stdin); print('✅ TG OK' if r.get('ok') else f'❌ TG 실패: {r}')"
        fi
        ;;
    sketch)
        echo "[CHAIN] S펜 스케치(선화) → TG 전송: $FNAME"
        CAPTION="🎨 S펜 스케치 선화 추출 ($TS)"
        curl -s -X POST \
            "https://api.telegram.org/bot${BOT_TOKEN}/sendPhoto" \
            -F "chat_id=$CHAT_ID" \
            -F "photo=@${FILE}" \
            -F "caption=$CAPTION" \
            | python3 -c "import sys,json; r=json.load(sys.stdin); print('✅ TG OK' if r.get('ok') else f'❌ TG 실패: {r}')"
        ;;
    *)
        echo "알 수 없는 유형: $TYPE (screenshot|record|sketch 중 하나)"
        exit 1
        ;;
esac
