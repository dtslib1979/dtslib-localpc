# setup-all.ps1 — 원클릭 전체 인프라 구축
# 용도: 집에 가서 이것만 실행하면 CLI 통합 전환 완료
# 실행: powershell -ExecutionPolicy Bypass -File scripts/setup-all.ps1
# 권한: 관리자 권한으로 실행 (SSH, WSL 설치에 필요)

param(
    [switch]$DryRun,      # 실행 없이 계획만 표시
    [switch]$SkipSSH,
    [switch]$SkipCLI,
    [switch]$SkipWSL
)

$ErrorActionPreference = "Continue"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

function Write-Phase($num, $name, $time) {
    Write-Host ""
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host "  Phase $num: $name ($time)" -ForegroundColor White
    Write-Host "============================================" -ForegroundColor Cyan
}

function Test-Admin {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# === 사전 체크 ===
Write-Host ""
Write-Host "########################################" -ForegroundColor Green
Write-Host "#  PARKSY INFRA SETUP — CLI 통합 전환  #" -ForegroundColor Green
Write-Host "#  docs/INFRA_WHITEPAPER.md 기반       #" -ForegroundColor Green
Write-Host "########################################" -ForegroundColor Green
Write-Host ""

if (-not (Test-Admin)) {
    Write-Host "[WARN] 관리자 권한 아님 — SSH/WSL 설치가 실패할 수 있음" -ForegroundColor Yellow
    Write-Host "관리자 PowerShell에서 다시 실행을 권장합니다." -ForegroundColor Yellow
    Write-Host ""
    $continue = Read-Host "그래도 계속? (y/N)"
    if ($continue -ne "y") { exit 0 }
}

if ($DryRun) {
    Write-Host "[DRY RUN] 실행 없이 계획만 표시합니다." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Phase 1: Claude Code CLI 설치 (3분)" -ForegroundColor White
    Write-Host "  - Node.js 18+ 확인" -ForegroundColor Gray
    Write-Host "  - npm install -g @anthropic-ai/claude-code" -ForegroundColor Gray
    Write-Host "  - MCP 서버 3개 추가 (Puppeteer, GitHub, Filesystem)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Phase 2: SSH 서버 설정 (5분)" -ForegroundColor White
    Write-Host "  - OpenSSH Server 설치" -ForegroundColor Gray
    Write-Host "  - sshd 서비스 시작 + 자동시작" -ForegroundColor Gray
    Write-Host "  - 방화벽 규칙 추가" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Phase 3: WSL + tmux + Telegram Bot (25분)" -ForegroundColor White
    Write-Host "  - WSL Ubuntu 설치" -ForegroundColor Gray
    Write-Host "  - tmux, python3, pip 설치" -ForegroundColor Gray
    Write-Host "  - Telegram Bot 환경 구성" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Phase 4: 검증 (5분)" -ForegroundColor White
    Write-Host "  - 전체 인프라 검증 스크립트 실행" -ForegroundColor Gray
    Write-Host ""
    Write-Host "총 예상 시간: ~38분" -ForegroundColor Cyan
    exit 0
}

$startTime = Get-Date
$phaseResults = @()

# === Phase 1: Claude Code CLI ===
if (-not $SkipCLI) {
    Write-Phase 1 "Claude Code CLI + MCP" "3분"
    try {
        & powershell -ExecutionPolicy Bypass -File "$scriptDir\setup-cli.ps1"
        $phaseResults += [PSCustomObject]@{Phase=1; Name="CLI + MCP"; Status="OK"}
    } catch {
        $phaseResults += [PSCustomObject]@{Phase=1; Name="CLI + MCP"; Status="FAIL: $_"}
    }
} else {
    $phaseResults += [PSCustomObject]@{Phase=1; Name="CLI + MCP"; Status="SKIP"}
}

# === Phase 2: SSH 서버 ===
if (-not $SkipSSH) {
    Write-Phase 2 "SSH 서버" "5분"
    try {
        & powershell -ExecutionPolicy Bypass -File "$scriptDir\setup-ssh.ps1"
        $phaseResults += [PSCustomObject]@{Phase=2; Name="SSH Server"; Status="OK"}
    } catch {
        $phaseResults += [PSCustomObject]@{Phase=2; Name="SSH Server"; Status="FAIL: $_"}
    }
} else {
    $phaseResults += [PSCustomObject]@{Phase=2; Name="SSH Server"; Status="SKIP"}
}

# === Phase 3: WSL 환경 ===
if (-not $SkipWSL) {
    Write-Phase 3 "WSL + tmux + Telegram Bot" "25분"
    try {
        & powershell -ExecutionPolicy Bypass -File "$scriptDir\setup-wsl.ps1"
        $phaseResults += [PSCustomObject]@{Phase=3; Name="WSL Environment"; Status="OK"}
    } catch {
        $phaseResults += [PSCustomObject]@{Phase=3; Name="WSL Environment"; Status="FAIL: $_"}
    }
} else {
    $phaseResults += [PSCustomObject]@{Phase=3; Name="WSL Environment"; Status="SKIP"}
}

# === Phase 4: 검증 ===
Write-Phase 4 "전체 검증" "5분"
try {
    & powershell -ExecutionPolicy Bypass -File "$scriptDir\verify-infra.ps1"
    $phaseResults += [PSCustomObject]@{Phase=4; Name="Verification"; Status="OK"}
} catch {
    $phaseResults += [PSCustomObject]@{Phase=4; Name="Verification"; Status="FAIL: $_"}
}

# === 결과 요약 ===
$elapsed = (Get-Date) - $startTime

Write-Host ""
Write-Host "########################################" -ForegroundColor Cyan
Write-Host "#         설치 결과 요약               #" -ForegroundColor Cyan
Write-Host "########################################" -ForegroundColor Cyan
Write-Host ""

$phaseResults | Format-Table -AutoSize

$failures = ($phaseResults | Where-Object { $_.Status -like "FAIL*" }).Count
$skips = ($phaseResults | Where-Object { $_.Status -eq "SKIP" }).Count

Write-Host "소요 시간: $($elapsed.Minutes)분 $($elapsed.Seconds)초" -ForegroundColor White
Write-Host ""

if ($failures -eq 0) {
    Write-Host "전체 성공!" -ForegroundColor Green
    Write-Host ""
    Write-Host "다음 단계:" -ForegroundColor White
    Write-Host "  1. 폰 Termux에서 SSH 접속 테스트" -ForegroundColor Yellow
    Write-Host "  2. tmux 워크스페이스 실행: bash scripts/tmux-workspace.sh" -ForegroundColor Yellow
    Write-Host "  3. Telegram Bot 토큰 설정 후 실행" -ForegroundColor Yellow
} else {
    Write-Host "$failures 개 Phase 실패. 위 로그 확인 후 개별 재실행." -ForegroundColor Red
}

Write-Host ""
