#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# dtslib-localpc :: Claude Code Hook 설치 스크립트 (Linux/Mac)
# ═══════════════════════════════════════════════════════════════
#
# 용도: 3개 프로덕션 레포에 Stop hook 자동 설치
#       → Claude 세션 종료 시 세션 로그 작성 강제
#
# 실행: bash scripts/install-hooks.sh
# 제거: bash scripts/install-hooks.sh --uninstall
# ═══════════════════════════════════════════════════════════════

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
HOOK_SCRIPT="$REPO_ROOT/hooks/stop-session-log.sh"
UNINSTALL=false

if [ "${1:-}" = "--uninstall" ]; then
    UNINSTALL=true
fi

# ── 프로덕션 레포 경로 (Linux/WSL) ──
# Windows Git Bash와 Linux 환경 모두 지원
declare -A REPOS
REPOS=(
    ["parksy-audio"]="${PARKSY_AUDIO_PATH:-/d/PARKSY/parksy-audio}"
    ["parksy-image"]="${PARKSY_IMAGE_PATH:-/d/parksy-image}"
    ["dtslib-apk-lab"]="${DTSLIB_APK_LAB_PATH:-/d/1_GITHUB/dtslib-apk-lab}"
)

echo ""
echo "═══════════════════════════════════════════"
if $UNINSTALL; then
    echo "  Claude Code Hook 제거"
else
    echo "  Claude Code Hook 설치"
fi
echo "═══════════════════════════════════════════"
echo ""

# ── hook 스크립트 확인 ──
if [ ! -f "$HOOK_SCRIPT" ]; then
    echo "ERROR: Hook script not found: $HOOK_SCRIPT"
    exit 1
fi

installed=0
skipped=0

for repo_name in "${!REPOS[@]}"; do
    repo_path="${REPOS[$repo_name]}"

    if [ ! -d "$repo_path" ]; then
        echo "  SKIP: $repo_name — $repo_path not found"
        ((skipped++))
        continue
    fi

    claude_dir="$repo_path/.claude"
    settings_path="$claude_dir/settings.local.json"

    if $UNINSTALL; then
        if [ -f "$settings_path" ]; then
            rm -f "$settings_path"
            echo "  REMOVED: $repo_name — $settings_path"
            ((installed++))
        else
            echo "  SKIP: $repo_name — no settings.local.json"
            ((skipped++))
        fi
    else
        mkdir -p "$claude_dir"

        # settings.local.json 생성
        cat > "$settings_path" <<SETTINGS
{
  "hooks": {
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "bash \"$HOOK_SCRIPT\""
          }
        ]
      }
    ]
  }
}
SETTINGS

        echo "  OK: $repo_name — $settings_path"
        ((installed++))
    fi
done

echo ""
echo "─────────────────────────────────────────"

if $UNINSTALL; then
    echo "  제거 완료: ${installed}개 / 스킵: ${skipped}개"
else
    echo "  설치 완료: ${installed}개 / 스킵: ${skipped}개"
    echo ""
    echo "  Hook script: $HOOK_SCRIPT"
    echo "  대상: .claude/settings.local.json (gitignored)"
    echo ""
    echo "  환경변수로 경로 오버라이드 가능:"
    echo "    PARKSY_AUDIO_PATH=/your/path bash scripts/install-hooks.sh"
fi

echo ""
