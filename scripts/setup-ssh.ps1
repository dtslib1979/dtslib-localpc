# setup-ssh.ps1 — Windows OpenSSH 서버 자동 세팅
# 용도: PC를 SSH 서버로 만들어 폰에서 원격 접속 가능하게 함
# 실행: powershell -ExecutionPolicy Bypass -File scripts/setup-ssh.ps1
# 권한: 관리자 권한 필요

param(
    [switch]$Uninstall,
    [int]$Port = 22,
    [switch]$KeyAuthOnly  # 비밀번호 인증 비활성화 (키 인증만)
)

$ErrorActionPreference = "Stop"

function Write-Step($num, $msg) {
    Write-Host "`n[$num] $msg" -ForegroundColor Cyan
}

function Test-Admin {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# === 관리자 권한 체크 ===
if (-not (Test-Admin)) {
    Write-Host "[ERROR] 관리자 권한으로 실행해야 합니다." -ForegroundColor Red
    Write-Host "PowerShell을 '관리자 권한으로 실행'한 뒤 다시 시도하세요." -ForegroundColor Yellow
    exit 1
}

# === 제거 모드 ===
if ($Uninstall) {
    Write-Step 1 "OpenSSH 서버 중지..."
    Stop-Service sshd -ErrorAction SilentlyContinue
    Set-Service -Name sshd -StartupType Disabled -ErrorAction SilentlyContinue

    Write-Step 2 "방화벽 규칙 제거..."
    Remove-NetFirewallRule -Name "sshd-dtslib" -ErrorAction SilentlyContinue

    Write-Host "`n[DONE] SSH 서버 비활성화 완료." -ForegroundColor Green
    Write-Host "완전 제거: Remove-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0" -ForegroundColor Yellow
    exit 0
}

# === Phase 1: OpenSSH 서버 설치 ===
Write-Step 1 "OpenSSH 서버 설치 확인..."

$sshCapability = Get-WindowsCapability -Online | Where-Object Name -like 'OpenSSH.Server*'

if ($sshCapability.State -eq "Installed") {
    Write-Host "  이미 설치됨 (skip)" -ForegroundColor Green
} else {
    Write-Host "  설치 중..." -ForegroundColor Yellow
    Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
    Write-Host "  설치 완료" -ForegroundColor Green
}

# === Phase 2: sshd 서비스 시작 + 자동시작 ===
Write-Step 2 "sshd 서비스 설정..."

Set-Service -Name sshd -StartupType Automatic
Start-Service sshd

$svc = Get-Service sshd
if ($svc.Status -eq "Running") {
    Write-Host "  sshd 실행 중 (자동시작 설정됨)" -ForegroundColor Green
} else {
    Write-Host "  [ERROR] sshd 시작 실패" -ForegroundColor Red
    exit 1
}

# === Phase 3: 포트 설정 ===
Write-Step 3 "SSH 포트 설정 (Port $Port)..."

$sshdConfig = "C:\ProgramData\ssh\sshd_config"
if (Test-Path $sshdConfig) {
    $content = Get-Content $sshdConfig -Raw

    # 포트 변경 (기본 22가 아닌 경우)
    if ($Port -ne 22) {
        if ($content -match "^#?Port\s+\d+") {
            $content = $content -replace "^#?Port\s+\d+", "Port $Port"
        } else {
            $content = "Port $Port`n" + $content
        }
        Write-Host "  포트 $Port로 설정" -ForegroundColor Yellow
    } else {
        Write-Host "  기본 포트 22 사용" -ForegroundColor Green
    }

    # 키 인증만 사용 (옵션)
    if ($KeyAuthOnly) {
        $content = $content -replace "^#?PasswordAuthentication\s+\w+", "PasswordAuthentication no"
        Write-Host "  비밀번호 인증 비활성화 (키 인증만)" -ForegroundColor Yellow
    }

    Set-Content -Path $sshdConfig -Value $content
    Restart-Service sshd
} else {
    Write-Host "  [WARN] sshd_config 없음 — 기본 설정 사용" -ForegroundColor Yellow
}

# === Phase 4: 방화벽 규칙 ===
Write-Step 4 "방화벽 규칙 설정..."

# 기존 규칙 제거 후 재생성
Remove-NetFirewallRule -Name "sshd-dtslib" -ErrorAction SilentlyContinue

New-NetFirewallRule -Name "sshd-dtslib" `
    -DisplayName "OpenSSH Server (dtslib-localpc)" `
    -Description "SSH remote access for Park CLI workflow" `
    -Enabled True `
    -Direction Inbound `
    -Protocol TCP `
    -Action Allow `
    -LocalPort $Port | Out-Null

Write-Host "  인바운드 TCP $Port 허용" -ForegroundColor Green

# === Phase 5: SSH 키 디렉토리 준비 ===
Write-Step 5 "SSH 키 디렉토리 준비..."

$sshDir = "$env:USERPROFILE\.ssh"
if (-not (Test-Path $sshDir)) {
    New-Item -ItemType Directory -Path $sshDir -Force | Out-Null
    Write-Host "  $sshDir 생성" -ForegroundColor Green
} else {
    Write-Host "  $sshDir 이미 존재" -ForegroundColor Green
}

$authorizedKeys = "$sshDir\authorized_keys"
if (-not (Test-Path $authorizedKeys)) {
    New-Item -ItemType File -Path $authorizedKeys -Force | Out-Null
    Write-Host "  authorized_keys 생성 (비어있음 — 폰 공개키 추가 필요)" -ForegroundColor Yellow
}

# === Phase 6: 접속 정보 출력 ===
Write-Step 6 "접속 정보..."

$username = $env:USERNAME
$ips = Get-NetIPAddress -AddressFamily IPv4 |
    Where-Object { $_.InterfaceAlias -notmatch "Loopback" -and $_.IPAddress -ne "127.0.0.1" } |
    Select-Object -ExpandProperty IPAddress

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  SSH 서버 세팅 완료!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "접속 명령어 (폰 Termux에서):" -ForegroundColor White
foreach ($ip in $ips) {
    if ($Port -eq 22) {
        Write-Host "  ssh $username@$ip" -ForegroundColor Yellow
    } else {
        Write-Host "  ssh -p $Port $username@$ip" -ForegroundColor Yellow
    }
}
Write-Host ""
Write-Host "SSH 키 등록 (폰 Termux에서):" -ForegroundColor White
foreach ($ip in $ips) {
    if ($Port -eq 22) {
        Write-Host "  ssh-copy-id $username@$ip" -ForegroundColor Yellow
    } else {
        Write-Host "  ssh-copy-id -p $Port $username@$ip" -ForegroundColor Yellow
    }
}
Write-Host ""
Write-Host "상태 확인:" -ForegroundColor White
Write-Host "  Get-Service sshd" -ForegroundColor Yellow
Write-Host "  netstat -an | findstr :$Port" -ForegroundColor Yellow
Write-Host ""
