#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# dtslib-localpc :: SessionStart Hook — 비정상 종료 세션 복구
# ═══════════════════════════════════════════════════════════════
#
# Claude Code SessionStart hook.
# 이전 세션이 비정상 종료(서버 다운, PC 다운, 네트워크 끊김)된 경우
# 세션 로그 누락을 감지하고 Claude에게 catch-up 로그 작성을 지시한다.
#
# 동작 원리:
#   1. 세션 시작 시 자동 실행
#   2. 이전 세션의 마커 파일(.sessions/{repo}.json) 확인
#   3. 마커 있음 + 세션 로그 없음 = 이전 세션 비정상 종료
#   4. stdout으로 복구 지시 → Claude context에 자동 주입
#   5. 현재 세션용 마커 생성
#
# 마커 파일은 정상 종료 시 Stop hook이 삭제한다.
# 비정상 종료 시 마커가 남아있어서 다음 세션이 감지할 수 있다.
# ═══════════════════════════════════════════════════════════════

set -euo pipefail

INPUT=$(cat)

# ── 현재 레포 감지 ──
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
REPO_NAME=$(basename "$REPO_ROOT")

# ── 프로덕션 레포 필터 ──
case "$REPO_NAME" in
    parksy-audio|parksy-image|dtslib-apk-lab)
        ;;
    *)
        exit 0
        ;;
esac

# ── dtslib-localpc 경로 탐색 ──
LOCALPC=""
CANDIDATES=(
    "${DTSLIB_LOCALPC:-}"
    "/d/1_GITHUB/dtslib-localpc"
    "/mnt/d/1_GITHUB/dtslib-localpc"
    "D:/1_GITHUB/dtslib-localpc"
    "$HOME/dtslib-localpc"
    "$HOME/1_GITHUB/dtslib-localpc"
    "$(dirname "$REPO_ROOT")/dtslib-localpc"
)

for candidate in "${CANDIDATES[@]}"; do
    if [ -n "$candidate" ] && [ -f "$candidate/repos/status.json" ]; then
        LOCALPC="$candidate"
        break
    fi
done

[ -z "$LOCALPC" ] && exit 0

# ── 경로 설정 ──
MARKER_DIR="$LOCALPC/.sessions"
MARKER_FILE="$MARKER_DIR/${REPO_NAME}.json"
JOURNAL="$LOCALPC/repos/${REPO_NAME}.md"

# ── 이전 세션 마커 확인 ──
if [ -f "$MARKER_FILE" ]; then
    # 마커에서 이전 세션 정보 읽기
    PREV_START=""
    PREV_DATE=""

    if command -v jq &>/dev/null; then
        PREV_START=$(jq -r '.started // empty' "$MARKER_FILE" 2>/dev/null)
    fi

    # jq 없으면 grep으로 파싱
    if [ -z "$PREV_START" ]; then
        PREV_START=$(grep -o '"started":"[^"]*"' "$MARKER_FILE" 2>/dev/null | cut -d'"' -f4)
    fi

    if [ -n "$PREV_START" ]; then
        PREV_DATE=$(echo "$PREV_START" | cut -c1-10)
    fi

    # 이전 세션 날짜의 로그가 있는지 확인
    LOG_EXISTS=false
    if [ -n "$PREV_DATE" ] && [ -f "$JOURNAL" ] && grep -q "^### $PREV_DATE" "$JOURNAL" 2>/dev/null; then
        LOG_EXISTS=true
    fi

    if [ "$LOG_EXISTS" = false ]; then
        # ── stdout으로 복구 지시 (Claude context에 주입됨) ──
        cat <<RECOVERY
════════════════════════════════════════════════════════════════
 [세션 복구 필요] ${REPO_NAME} — 이전 세션 비정상 종료 감지
════════════════════════════════════════════════════════════════

이전 세션 시작: ${PREV_START:-불명}
세션 로그 상태: 미작성 (${PREV_DATE:-날짜 불명} 로그 없음)

이전 세션이 서버 다운/PC 다운/네트워크 끊김으로 비정상 종료되었다.
세션 로그가 유실된 상태. 아래 순서로 catch-up 로그를 작성하라:

1. git log --since='${PREV_START:-yesterday}' --oneline  ← 이전 세션 커밋 확인
2. git diff HEAD~5 --stat  ← 최근 변경 파일 확인
3. 확인된 내용으로 catch-up 세션 로그 작성:

   ${LOCALPC}/repos/${REPO_NAME}.md 끝에 append:
   ---
   ### ${PREV_DATE:-YYYY-MM-DD} | [RECOVERY] 비정상 종료 세션 복구
   **작업**: (git log/diff에서 확인된 내용)
   **결정**: (커밋 메시지에서 추론)
   **결과**: (비정상 종료로 인해 불완전할 수 있음)
   **교훈**: 세션 비정상 종료. 이 로그는 git 이력 기반 복구본.
   **재구축 힌트**: (가능한 범위에서 작성)
   ---

4. catch-up 로그 작성 후 이번 세션 본 작업 시작

════════════════════════════════════════════════════════════════
RECOVERY
    fi
fi

# ── 현재 세션 마커 생성 ──
mkdir -p "$MARKER_DIR"
cat > "$MARKER_FILE" <<MARKER
{"repo":"${REPO_NAME}","started":"$(date +%Y-%m-%dT%H:%M:%S%z)","cwd":"${REPO_ROOT}"}
MARKER

exit 0
