#!/bin/bash
# 5lane_recovery.sh — 5-Lane Agent 복구 스크립트
# 폰/탭 재부팅 후 모든 에이전트 세션 자동 재개
#
# 사용법:
#   bash 5lane_recovery.sh              # 전체 재시작
#   bash 5lane_recovery.sh --check      # 상태만 확인
#   bash 5lane_recovery.sh phone        # 폰만 재시작
#   bash 5lane_recovery.sh tab          # 탭만 재시작

PHONE_IP=$(cat ~/.phone_ip 2>/dev/null)
TAB_IP=$(cat ~/.tab_ip 2>/dev/null || echo "100.74.21.77")
SSH_OPTS="-p 8022 -o ConnectTimeout=5 -o StrictHostKeyChecking=no"

# ── 색상 ──
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

check_status() {
    local label=$1 ip=$2
    local result=$(ssh $SSH_OPTS $ip "echo OK" 2>&1)
    if echo "$result" | grep -q "OK"; then
        echo -e "${GREEN}✅ $label 연결됨${NC}"
        return 0
    else
        echo -e "${RED}❌ $label 연결 불가: $result${NC}"
        return 1
    fi
}

check_agent() {
    local ip=$1 session=$2
    local exists=$(ssh $SSH_OPTS $ip "tmux ls 2>/dev/null | grep '$session'" 2>&1)
    if [ -n "$exists" ]; then
        echo -e "${GREEN}  ✅ $session 실행중${NC}"
        return 0
    else
        echo -e "${YELLOW}  ⚠️  $session 없음${NC}"
        return 1
    fi
}

start_agent() {
    local ip=$1 session=$2 agent=$3
    echo -e "  → ${YELLOW}$session 시작...${NC}"
    ssh $SSH_OPTS $ip "tmux new -d -s $session '$agent'" 2>&1
    sleep 1
    if ssh $SSH_OPTS $ip "tmux ls 2>/dev/null | grep '$session'" >/dev/null 2>&1; then
        echo -e "  ${GREEN}✅ $session 시작됨${NC}"
    else
        echo -e "  ${RED}❌ $session 시작 실패${NC}"
    fi
}

# ── 모드: --check ──
if [ "$1" = "--check" ]; then
    echo "=== 5-Lane Agent 상태 ==="
    check_status "폰 (S25 Ultra)" $PHONE_IP && {
        check_agent $PHONE_IP "phone_claude"
        check_agent $PHONE_IP "phone_aider"
    }
    check_status "탭 (Tab S9 5G)" $TAB_IP && {
        check_agent $TAB_IP "tab_claude"
        check_agent $TAB_IP "tab_aider"
    }
    echo ""
    echo "WSL 메인 Claude Code: $(tmux ls 2>/dev/null | grep -c 'main_claude' || echo '0') 세션"
    exit 0
fi

# ── 모드: 특정 디바이스 ──
RESTORE_PHONE=false
RESTORE_TAB=false

if [ $# -eq 0 ] || [ "$1" = "all" ]; then
    RESTORE_PHONE=true
    RESTORE_TAB=true
elif [ "$1" = "phone" ]; then
    RESTORE_PHONE=true
elif [ "$1" = "tab" ]; then
    RESTORE_TAB=true
fi

# ── 폰 복구 ──
if $RESTORE_PHONE; then
    echo "=== 폰 (S25 Ultra) Agent 복구 ==="
    if check_status "폰" $PHONE_IP; then
        # 기존 세션 정리 (중복 방지)
        ssh $SSH_OPTS $PHONE_IP "tmux kill-session -t phone_claude 2>/dev/null; tmux kill-session -t phone_aider 2>/dev/null"
        sleep 1

        # Claude Code 폰 세션
        if ssh $SSH_OPTS $PHONE_IP "which claude" >/dev/null 2>&1; then
            start_agent $PHONE_IP "phone_claude" "claude"
        else
            echo -e "${YELLOW}  ⚠️  claude CLI 없음 — 설치 필요${NC}"
        fi

        # Aider 폰 세션
        if ssh $SSH_OPTS $PHONE_IP "which aider" >/dev/null 2>&1; then
            start_agent $PHONE_IP "phone_aider" "aider"
        else
            echo -e "${YELLOW}  ⚠️  aider CLI 없음 — 설치 필요${NC}"
        fi
    fi
fi

# ── 탭 복구 ──
if $RESTORE_TAB; then
    echo "=== 탭 (Tab S9 5G) Agent 복구 ==="
    if check_status "탭" $TAB_IP; then
        # 기존 세션 정리
        ssh $SSH_OPTS $TAB_IP "tmux kill-session -t tab_claude 2>/dev/null; tmux kill-session -t tab_aider 2>/dev/null"
        sleep 1

        if ssh $SSH_OPTS $TAB_IP "which claude" >/dev/null 2>&1; then
            start_agent $TAB_IP "tab_claude" "claude"
        fi

        if ssh $SSH_OPTS $TAB_IP "which aider" >/dev/null 2>&1; then
            start_agent $TAB_IP "tab_aider" "aider"
        fi
    fi
fi

# ── 최종 상태 ──
echo ""
echo "=== 최종 상태 ==="
bash "$0" --check
