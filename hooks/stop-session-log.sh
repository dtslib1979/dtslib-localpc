#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# dtslib-localpc :: Stop Hook — 세션 로그 프로토콜 강제
# ═══════════════════════════════════════════════════════════════
#
# Claude Code Stop hook.
# 프로덕션 레포(parksy-audio, parksy-image, dtslib-apk-lab) 세션에서
# dtslib-localpc/repos/{repo}.md에 세션 로그를 안 썼으면 블록한다.
#
# 설치: scripts/install-hooks.ps1 (Windows) 또는 scripts/install-hooks.sh (Linux)
# 위치: 각 프로덕션 레포의 .claude/settings.local.json → Stop hook command
#
# 동작 원리:
#   1. Claude 응답 끝날 때마다 자동 실행
#   2. 프로덕션 레포가 아니면 → 통과 (exit 0)
#   3. 오늘 세션 로그가 이미 있으면 → 통과 (exit 0)
#   4. 없으면 → 블록 (exit 2) + Claude에게 포맷/경로 안내
#   5. Claude가 로그 작성 후 재시도 → stop_hook_active=true → 통과
# ═══════════════════════════════════════════════════════════════

set -euo pipefail

# ── stdin에서 hook context 읽기 ──
INPUT=$(cat)

# ── 무한루프 방지 ──
# 한 번 블록 후 Claude가 대응 중이면 통과시킨다
if echo "$INPUT" | grep -q '"stop_hook_active"[[:space:]]*:[[:space:]]*true'; then
    exit 0
fi

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
# 우선순위: 환경변수 → Windows 공통 경로 → Linux 공통 경로 → 상대 경로
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

if [ -z "$LOCALPC" ]; then
    # dtslib-localpc를 못 찾으면 블록하지 않고 경고만
    echo "[session-log-hook] WARN: dtslib-localpc 경로를 찾을 수 없음. DTSLIB_LOCALPC 환경변수 설정 필요." >&2
    exit 0
fi

# ── 오늘 세션 로그 존재 여부 확인 ──
JOURNAL="$LOCALPC/repos/${REPO_NAME}.md"
TODAY=$(date +%Y-%m-%d)

# 저널 파일이 있고, 오늘 날짜의 로그가 있으면 통과
if [ -f "$JOURNAL" ] && grep -q "^### $TODAY" "$JOURNAL"; then
    # ── 세션 마커 삭제 (정상 종료) ──
    MARKER_FILE="$LOCALPC/.sessions/${REPO_NAME}.json"
    rm -f "$MARKER_FILE" 2>/dev/null
    exit 0
fi

# ── 블록: 세션 로그 미작성 ──
cat >&2 <<BLOCK
════════════════════════════════════════════════════════════════
 [자동 감지] ${REPO_NAME} 세션 로그 미작성
════════════════════════════════════════════════════════════════

이 세션에서 프로덕션 작업을 했다면 종료 전에 반드시:

1) ${LOCALPC}/repos/${REPO_NAME}.md 끝에 세션 로그 append:

   ---
   ### ${TODAY} | 세션 요약 한 줄
   **작업**: 구체적으로 뭘 했는지 (파일명, 함수명, 파라미터)
   **결정**: 왜 그렇게 했는지 (비교 대상, 시도한 대안, 버린 이유)
   **결과**: 수치 포함 (점수, 파일 크기, 에러 메시지)
   **교훈**: 다음 세션이 반드시 알아야 할 것
   **재구축 힌트**: D: 유실 시 이걸 다시 만들려면 Claude에게 이렇게 시켜라
   ---

2) ${LOCALPC}/repos/status.json 관련 필드 갱신

3) dtslib-localpc에서 git add + commit + push

단순 질문/조회만 한 세션이면 위 무시하고 그냥 종료 가능.
════════════════════════════════════════════════════════════════
BLOCK

exit 2
