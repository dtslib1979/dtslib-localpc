#!/bin/bash
# mcp_uptime_monitor.sh — 5분 간격 MCP 헬스체크 + 텔레그램 알림
# 설치: crontab -e  →  */5 * * * * ~/dtslib-localpc/scripts/mcp_uptime_monitor.sh

MCP_SERVERS=("rawmat:8101" "scm:8102" "platform:8103" "knowledge:8104")
LOG_DIR="$HOME/dtslib-localpc/logs"
LOG_FILE="$LOG_DIR/mcp_uptime.log"
ALERT_FILE="$LOG_DIR/mcp_alert.sent"

# 텔레그램 설정
TG_TOKEN=$(grep TG_BOT_TOKEN ~/dtslib-papyrus/.env 2>/dev/null | cut -d= -f2)
TG_CHAT=$(grep TG_CHAT_ID ~/dtslib-papyrus/.env 2>/dev/null | cut -d= -f2)
[ -z "$TG_TOKEN" ] && { echo "[ERROR] TG_TOKEN 없음"; exit 1; }
[ -z "$TG_CHAT" ] && TG_CHAT="6858098283"

mkdir -p "$LOG_DIR"

check_mcp() {
    local name=$1 port=$2
    timeout 3 bash -c "echo > /dev/tcp/localhost/$port" 2>/dev/null && echo "UP" || echo "DOWN"
}

alert_telegram() {
    local msg="$1"
    curl -s -X POST "https://api.telegram.org/bot${TG_TOKEN}/sendMessage" \
        -d "chat_id=${TG_CHAT}&text=${msg}" >/dev/null 2>&1
}

# Tailscale 상태
TS_STATUS=$(tailscale status 2>/dev/null | head -3 | tr '\n' ' | ')

# MCP 상태 체크
DOWN_SERVERS=""
ALL_UP=true
TIMESTAMP=$(date '+%Y-%m-%d %H:%M')

for entry in "${MCP_SERVERS[@]}"; do
    name="${entry%%:*}"
    port="${entry##*:}"
    status=$(check_mcp "$name" "$port")
    echo "$TIMESTAMP $name:$port $status" >> "$LOG_FILE"
    if [ "$status" = "DOWN" ]; then
        ALL_UP=false
        DOWN_SERVERS="$DOWN_SERVERS • $name (port $port)\n"
    fi
done

# 알림 (DOWN 상태일 때만, 중복 방지)
if [ "$ALL_UP" = false ]; then
    LAST_ALERT=$(cat "$ALERT_FILE" 2>/dev/null || echo "0")
    NOW=$(date +%s)
    if [ $((NOW - LAST_ALERT)) -gt 600 ]; then  # 10분 간격 중복 방지
        alert_telegram "🚨 MCP DOWN 감지%0A${DOWN_SERVERS}%0ATailscale: ${TS_STATUS}"
        echo "$NOW" > "$ALERT_FILE"
    fi
fi

# 로그 로테이션 (7일)
find "$LOG_DIR" -name "mcp_uptime.log" -mtime +7 -delete 2>/dev/null
