# ═══════════════════════════════════════════════════════════════
# dtslib-localpc :: Claude Code Hook 설치 스크립트 (Windows)
# ═══════════════════════════════════════════════════════════════
#
# 용도: 3개 프로덕션 레포에 Stop hook 자동 설치
#       → Claude 세션 종료 시 세션 로그 작성 강제
#
# 실행: powershell -File scripts/install-hooks.ps1
# 제거: powershell -File scripts/install-hooks.ps1 -Uninstall
# ═══════════════════════════════════════════════════════════════

param(
    [switch]$Uninstall
)

$ErrorActionPreference = "Stop"

# ── 경로 설정 ──
$repoRoot = Split-Path -Parent $PSScriptRoot  # dtslib-localpc root
$hookScript = Join-Path $repoRoot "hooks" "stop-session-log.sh"

# Git Bash 경로로 변환 (Windows → /d/... 형식)
$hookScriptUnix = $hookScript -replace '\\','/' -replace '^([A-Z]):',{ '/' + $_.Groups[1].Value.ToLower() }

$productionRepos = @(
    @{ Name = "parksy-audio";   Path = "D:\PARKSY\parksy-audio" }
    @{ Name = "parksy-image";   Path = "D:\parksy-image" }
    @{ Name = "dtslib-apk-lab"; Path = "D:\1_GITHUB\dtslib-apk-lab" }
)

Write-Host ""
Write-Host "═══════════════════════════════════════════" -ForegroundColor Cyan

if ($Uninstall) {
    Write-Host "  Claude Code Hook 제거" -ForegroundColor Cyan
} else {
    Write-Host "  Claude Code Hook 설치" -ForegroundColor Cyan
}

Write-Host "═══════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# ── hook 스크립트 존재 확인 ──
if (-not (Test-Path $hookScript)) {
    Write-Host "ERROR: Hook script not found: $hookScript" -ForegroundColor Red
    exit 1
}

$installed = 0
$skipped = 0

foreach ($repo in $productionRepos) {
    $repoPath = $repo.Path
    $repoName = $repo.Name

    if (-not (Test-Path $repoPath)) {
        Write-Host "  SKIP: $repoName — $repoPath not found" -ForegroundColor Yellow
        $skipped++
        continue
    }

    $claudeDir = Join-Path $repoPath ".claude"
    $settingsPath = Join-Path $claudeDir "settings.local.json"

    if ($Uninstall) {
        # ── 제거 모드 ──
        if (Test-Path $settingsPath) {
            Remove-Item $settingsPath -Force
            Write-Host "  REMOVED: $repoName — $settingsPath" -ForegroundColor Green
            $installed++
        } else {
            Write-Host "  SKIP: $repoName — no settings.local.json" -ForegroundColor Yellow
            $skipped++
        }
    } else {
        # ── 설치 모드 ──
        if (-not (Test-Path $claudeDir)) {
            New-Item -ItemType Directory -Path $claudeDir -Force | Out-Null
        }

        # settings.local.json 생성 (기존 파일 있으면 hooks만 머지)
        $settings = @{}
        if (Test-Path $settingsPath) {
            try {
                $existing = Get-Content $settingsPath -Raw | ConvertFrom-Json
                # 기존 설정을 해시테이블로 변환
                $existing.PSObject.Properties | ForEach-Object {
                    $settings[$_.Name] = $_.Value
                }
            } catch {
                Write-Host "  WARN: $repoName — 기존 settings.local.json 파싱 실패, 덮어씀" -ForegroundColor Yellow
            }
        }

        # hooks 설정 추가/갱신
        $settings["hooks"] = @{
            Stop = @(
                @{
                    matcher = ""
                    hooks = @(
                        @{
                            type = "command"
                            command = "bash `"$hookScriptUnix`""
                        }
                    )
                }
            )
        }

        $settings | ConvertTo-Json -Depth 8 | Out-File -FilePath $settingsPath -Encoding UTF8
        Write-Host "  OK: $repoName — $settingsPath" -ForegroundColor Green
        $installed++
    }
}

Write-Host ""
Write-Host "─────────────────────────────────────────" -ForegroundColor Gray

if ($Uninstall) {
    Write-Host "  제거 완료: ${installed}개 / 스킵: ${skipped}개" -ForegroundColor Cyan
} else {
    Write-Host "  설치 완료: ${installed}개 / 스킵: ${skipped}개" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Hook script: $hookScript" -ForegroundColor Gray
    Write-Host "  대상: .claude/settings.local.json (gitignored)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  작동 확인:" -ForegroundColor Yellow
    Write-Host "    1. 프로덕션 레포에서 Claude Code 세션 시작" -ForegroundColor Gray
    Write-Host "    2. 작업 후 세션 종료 시도" -ForegroundColor Gray
    Write-Host "    3. 세션 로그 안 썼으면 자동 블록됨" -ForegroundColor Gray
}

Write-Host ""
