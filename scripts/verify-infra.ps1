# verify-infra.ps1 — CLI 통합 인프라 전체 검증
# 용도: 모든 Phase가 제대로 설치됐는지 한 번에 확인
# 실행: powershell -ExecutionPolicy Bypass -File scripts/verify-infra.ps1

$ErrorActionPreference = "Continue"

function Test-Command($cmd) {
    try {
        $null = & $cmd --version 2>&1
        return $true
    } catch {
        return $false
    }
}

Write-Host ""
Write-Host "=== PARKSY INFRA 전체 검증 ===" -ForegroundColor Cyan
Write-Host ""

$results = @()
$score = 0
$total = 0

function Add-Check($category, $item, $ok, $detail) {
    $script:total++
    if ($ok) { $script:score++ }
    $status = if ($ok) { "OK" } else { "FAIL" }
    $color = if ($ok) { "Green" } else { "Red" }
    Write-Host "  [$status] $item — $detail" -ForegroundColor $color
    $script:results += [PSCustomObject]@{
        Category = $category
        Item     = $item
        Status   = $status
        Detail   = $detail
    }
}

# ========================================
# Phase 1: Claude Code CLI
# ========================================
Write-Host "[Phase 1] Claude Code CLI" -ForegroundColor White

# Node.js
$nodeOk = Test-Command "node"
$nodeVer = if ($nodeOk) { (node --version 2>&1).ToString().Trim() } else { "미설치" }
Add-Check "CLI" "Node.js" $nodeOk $nodeVer

# npm
$npmOk = Test-Command "npm"
$npmVer = if ($npmOk) { (npm --version 2>&1).ToString().Trim() } else { "미설치" }
Add-Check "CLI" "npm" $npmOk $npmVer

# Claude Code
$claudeCheck = npm list -g @anthropic-ai/claude-code 2>&1
$claudeOk = $claudeCheck -match "claude-code@"
$claudeVer = if ($claudeOk) { ($claudeCheck | Select-String "claude-code@(.+)").Matches.Groups[1].Value } else { "미설치" }
Add-Check "CLI" "Claude Code CLI" $claudeOk $claudeVer

# claude 명령어
$claudeCmdOk = Test-Command "claude"
Add-Check "CLI" "claude 명령어" $claudeCmdOk $(if ($claudeCmdOk) { "실행 가능" } else { "PATH에 없음" })

Write-Host ""

# ========================================
# Phase 2: SSH 서버
# ========================================
Write-Host "[Phase 2] SSH 서버" -ForegroundColor White

# sshd 서비스
try {
    $sshd = Get-Service sshd -ErrorAction Stop
    $sshdOk = $sshd.Status -eq "Running"
    $sshdDetail = "$($sshd.Status), StartType=$($sshd.StartType)"
} catch {
    $sshdOk = $false
    $sshdDetail = "서비스 없음"
}
Add-Check "SSH" "sshd 서비스" $sshdOk $sshdDetail

# 방화벽 규칙
try {
    $fwRule = Get-NetFirewallRule -Name "sshd-dtslib" -ErrorAction Stop
    $fwOk = $fwRule.Enabled -eq $true
    $fwDetail = "Enabled=$($fwRule.Enabled), Action=$($fwRule.Action)"
} catch {
    # 기본 sshd 규칙도 확인
    try {
        $fwRule = Get-NetFirewallRule -DisplayName "*OpenSSH*" -ErrorAction Stop | Select-Object -First 1
        $fwOk = $fwRule.Enabled -eq $true
        $fwDetail = "기본 규칙: $($fwRule.DisplayName)"
    } catch {
        $fwOk = $false
        $fwDetail = "방화벽 규칙 없음"
    }
}
Add-Check "SSH" "방화벽 규칙" $fwOk $fwDetail

# 포트 리스닝
$portCheck = netstat -an 2>&1 | Select-String ":22\s+.*LISTENING"
$portOk = $null -ne $portCheck
Add-Check "SSH" "Port 22 리스닝" $portOk $(if ($portOk) { "LISTENING" } else { "안 열림" })

# authorized_keys
$authKeys = "$env:USERPROFILE\.ssh\authorized_keys"
$authOk = Test-Path $authKeys
$authDetail = if ($authOk) {
    $lines = (Get-Content $authKeys | Where-Object { $_ -match "\S" }).Count
    "${lines}개 키 등록"
} else { "파일 없음" }
Add-Check "SSH" "authorized_keys" $authOk $authDetail

# 접속 정보
$ips = Get-NetIPAddress -AddressFamily IPv4 |
    Where-Object { $_.InterfaceAlias -notmatch "Loopback" -and $_.IPAddress -ne "127.0.0.1" } |
    Select-Object -ExpandProperty IPAddress
$username = $env:USERNAME
foreach ($ip in $ips) {
    Add-Check "SSH" "접속 주소" $true "ssh $username@$ip"
}

Write-Host ""

# ========================================
# Phase 3: WSL 환경
# ========================================
Write-Host "[Phase 3] WSL 환경" -ForegroundColor White

# WSL 존재
try {
    $wslList = wsl --list --quiet 2>&1
    $wslOk = $wslList -match "Ubuntu"
    Add-Check "WSL" "WSL Ubuntu" $wslOk $(if ($wslOk) { "설치됨" } else { "미설치" })
} catch {
    Add-Check "WSL" "WSL" $false "WSL 미설치"
    $wslOk = $false
}

if ($wslOk) {
    # tmux
    $tmuxCheck = wsl bash -c "tmux -V 2>/dev/null || echo 'NOT_FOUND'" 2>&1
    $tmuxOk = $tmuxCheck -notmatch "NOT_FOUND"
    Add-Check "WSL" "tmux" $tmuxOk $tmuxCheck.Trim()

    # Python3
    $pyCheck = wsl bash -c "python3 --version 2>/dev/null || echo 'NOT_FOUND'" 2>&1
    $pyOk = $pyCheck -notmatch "NOT_FOUND"
    Add-Check "WSL" "Python3" $pyOk $pyCheck.Trim()

    # /mnt/d
    $dCheck = wsl bash -c "test -d /mnt/d && echo 'OK' || echo 'NO'" 2>&1
    $dOk = $dCheck -match "OK"
    Add-Check "WSL" "/mnt/d 접근" $dOk $(if ($dOk) { "D: 드라이브 공유 OK" } else { "접근 불가" })

    # tmux.conf
    $tmuxConf = wsl bash -c "test -f ~/.tmux.conf && echo 'OK' || echo 'NO'" 2>&1
    Add-Check "WSL" "tmux.conf" ($tmuxConf -match "OK") $(if ($tmuxConf -match "OK") { "설정됨" } else { "미설정" })

    # Telegram Bot
    $botCheck = wsl bash -c "test -f ~/telegram-bot/bot.py && echo 'OK' || echo 'NO'" 2>&1
    Add-Check "WSL" "Telegram Bot" ($botCheck -match "OK") $(if ($botCheck -match "OK") { "배포됨" } else { "미배포" })

    # Bot venv
    $venvCheck = wsl bash -c "test -d ~/telegram-bot/venv && echo 'OK' || echo 'NO'" 2>&1
    Add-Check "WSL" "Bot venv" ($venvCheck -match "OK") $(if ($venvCheck -match "OK") { "가상환경 OK" } else { "미생성" })
}

Write-Host ""

# ========================================
# 기존 인프라 (scripts/)
# ========================================
Write-Host "[기존] 자동화 스크립트" -ForegroundColor White

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$existingScripts = @(
    "snapshot.ps1",
    "sync-all.ps1",
    "health-check.ps1",
    "register-scheduler.ps1",
    "install-hooks.ps1",
    "install-hooks.sh"
)

foreach ($s in $existingScripts) {
    $path = Join-Path $scriptDir $s
    $exists = Test-Path $path
    Add-Check "Scripts" $s $exists $(if ($exists) { "존재" } else { "없음" })
}

Write-Host ""

# ========================================
# 결과 요약
# ========================================
$pct = [math]::Round(($score / $total) * 100)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  검증 결과: $score / $total ($pct%)" -ForegroundColor $(if ($pct -ge 80) { "Green" } elseif ($pct -ge 60) { "Yellow" } else { "Red" })
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$fails = $results | Where-Object { $_.Status -eq "FAIL" }
if ($fails.Count -gt 0) {
    Write-Host "실패 항목:" -ForegroundColor Red
    $fails | ForEach-Object { Write-Host "  - $($_.Category)/$($_.Item): $($_.Detail)" -ForegroundColor Red }
    Write-Host ""
    Write-Host "개별 스크립트로 수정:" -ForegroundColor Yellow
    Write-Host "  CLI:  powershell -File scripts/setup-cli.ps1" -ForegroundColor Yellow
    Write-Host "  SSH:  powershell -File scripts/setup-ssh.ps1" -ForegroundColor Yellow
    Write-Host "  WSL:  powershell -File scripts/setup-wsl.ps1" -ForegroundColor Yellow
} else {
    Write-Host "전체 인프라 정상!" -ForegroundColor Green
    Write-Host ""
    Write-Host "폰에서 접속:" -ForegroundColor White
    Write-Host "  ssh $username@<PC_IP>" -ForegroundColor Yellow
    Write-Host "  bash scripts/tmux-workspace.sh" -ForegroundColor Yellow
}

Write-Host ""

# 결과를 JSON으로 저장 (스냅샷용)
$snapshotDir = Split-Path -Parent $scriptDir | Join-Path -ChildPath "snapshots"
$jsonPath = Join-Path $snapshotDir "infra-verify.json"

$jsonResult = @{
    verified   = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    score      = $score
    total      = $total
    percentage = $pct
    results    = $results | ForEach-Object {
        @{
            category = $_.Category
            item     = $_.Item
            status   = $_.Status
            detail   = $_.Detail
        }
    }
} | ConvertTo-Json -Depth 3

Set-Content -Path $jsonPath -Value $jsonResult -Encoding UTF8
Write-Host "결과 저장: $jsonPath" -ForegroundColor Gray
