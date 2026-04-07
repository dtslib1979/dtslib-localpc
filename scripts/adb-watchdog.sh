#!/usr/bin/env bash
# ADB Watchdog — 태블릿 연결 자동 복구
# cron: */5 * * * * /home/dtsli/dtslib-localpc/scripts/adb-watchdog.sh

TABLET_IP="100.74.21.77"
PHONE_IP="$(cat ~/.phone_ip 2>/dev/null || echo '100.103.250.45')"
LAUNCH_PORT=7777
LOG="/home/dtsli/dtslib-localpc/logs/adb-watchdog.log"
MAX_LOG=500  # 최대 줄 수

mkdir -p "$(dirname "$LOG")"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG"
  # 로그 너무 길어지면 마지막 MAX_LOG줄만 유지
  if [ "$(wc -l < "$LOG")" -gt "$MAX_LOG" ]; then
    tail -n "$MAX_LOG" "$LOG" > "$LOG.tmp" && mv "$LOG.tmp" "$LOG"
  fi
}

check_and_reconnect() {
  local IP="$1"
  local LABEL="$2"

  # 연결 상태 확인
  if adb -s "$IP:5555" shell echo ok 2>/dev/null | grep -q ok; then
    return 0  # 이미 연결됨, 조용히 통과
  fi

  # 연결 시도
  log "⚠️  $LABEL 연결 끊김 → 재연결 시도"
  adb connect "$IP:5555" >> "$LOG" 2>&1

  # 재확인
  if adb -s "$IP:5555" shell echo ok 2>/dev/null | grep -q ok; then
    log "✅ $LABEL 재연결 성공"
    return 0
  else
    log "❌ $LABEL 재연결 실패 (ADB TCP 모드 꺼짐 — USB 연결 필요)"
    return 1
  fi
}

restore_tunnel() {
  local IP="$1"
  local LABEL="$2"
  local PORT="$3"

  # 터널 확인 (reverse 목록에 포트 있는지)
  if adb -s "$IP:5555" reverse --list 2>/dev/null | grep -q "tcp:$PORT"; then
    return 0  # 터널 살아있음
  fi

  # 터널 재설정
  if adb -s "$IP:5555" reverse tcp:$PORT tcp:$PORT >> "$LOG" 2>&1; then
    log "🔁 $LABEL 터널 tcp:$PORT 복구됨"
  fi
}

# ── 태블릿 체크 ──────────────────────────────────────────────
if check_and_reconnect "$TABLET_IP" "태블릿"; then
  restore_tunnel "$TABLET_IP" "태블릿" "$LAUNCH_PORT"
fi

# ── 폰 체크 ──────────────────────────────────────────────────
check_and_reconnect "$PHONE_IP" "폰"
