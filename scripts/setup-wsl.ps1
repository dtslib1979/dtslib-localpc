# setup-wsl.ps1 — WSL Ubuntu + tmux + Telegram Bot 환경 세팅
# 용도: Windows 안에 리눅스 서버 환경 구축 (Layer 3)
# 실행: powershell -ExecutionPolicy Bypass -File scripts/setup-wsl.ps1
# 권한: 관리자 권한 필요 (WSL 설치 시)

param(
    [switch]$SkipWSLInstall,  # WSL 이미 있으면 생략
    [switch]$Verify
)

$ErrorActionPreference = "Continue"

function Write-Step($num, $msg) {
    Write-Host "`n[$num] $msg" -ForegroundColor Cyan
}

function Test-Admin {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# === 검증 모드 ===
if ($Verify) {
    Write-Host "`n=== WSL 환경 검증 ===" -ForegroundColor Cyan
    $results = @()

    # WSL 존재
    try {
        $wslList = wsl --list --quiet 2>&1
        if ($wslList -match "Ubuntu") {
            $results += [PSCustomObject]@{Item="WSL Ubuntu"; Status="OK"; Detail="설치됨"}
        } else {
            $results += [PSCustomObject]@{Item="WSL Ubuntu"; Status="MISSING"; Detail="wsl --install -d Ubuntu"}
        }
    } catch {
        $results += [PSCustomObject]@{Item="WSL"; Status="MISSING"; Detail="WSL 미설치"}
    }

    # tmux
    $tmuxCheck = wsl bash -c "which tmux 2>/dev/null" 2>&1
    if ($tmuxCheck -match "tmux") {
        $results += [PSCustomObject]@{Item="tmux"; Status="OK"; Detail=$tmuxCheck.Trim()}
    } else {
        $results += [PSCustomObject]@{Item="tmux"; Status="MISSING"; Detail=""}
    }

    # Python3
    $pyCheck = wsl bash -c "python3 --version 2>/dev/null" 2>&1
    if ($pyCheck -match "Python") {
        $results += [PSCustomObject]@{Item="Python3 (WSL)"; Status="OK"; Detail=$pyCheck.Trim()}
    } else {
        $results += [PSCustomObject]@{Item="Python3 (WSL)"; Status="MISSING"; Detail=""}
    }

    # D: 드라이브 접근
    $dCheck = wsl bash -c "test -d /mnt/d && echo 'OK' || echo 'NO'" 2>&1
    if ($dCheck -match "OK") {
        $results += [PSCustomObject]@{Item="/mnt/d 접근"; Status="OK"; Detail="Windows D: 공유됨"}
    } else {
        $results += [PSCustomObject]@{Item="/mnt/d 접근"; Status="MISSING"; Detail=""}
    }

    # Telegram Bot 스크립트
    $botCheck = wsl bash -c "test -f ~/telegram-bot/bot.py && echo 'OK' || echo 'NO'" 2>&1
    if ($botCheck -match "OK") {
        $results += [PSCustomObject]@{Item="Telegram Bot"; Status="OK"; Detail="~/telegram-bot/bot.py"}
    } else {
        $results += [PSCustomObject]@{Item="Telegram Bot"; Status="NOT DEPLOYED"; Detail="setup-wsl.ps1 실행 필요"}
    }

    $results | Format-Table -AutoSize
    exit 0
}

# === Phase 1: WSL 설치 ===
if (-not $SkipWSLInstall) {
    if (-not (Test-Admin)) {
        Write-Host "[ERROR] WSL 설치에 관리자 권한 필요" -ForegroundColor Red
        exit 1
    }

    Write-Step 1 "WSL Ubuntu 설치 확인..."

    try {
        $wslList = wsl --list --quiet 2>&1
        if ($wslList -match "Ubuntu") {
            Write-Host "  이미 설치됨 (skip)" -ForegroundColor Green
        } else {
            Write-Host "  Ubuntu 설치 중... (재부팅 필요할 수 있음)" -ForegroundColor Yellow
            wsl --install -d Ubuntu 2>&1
            Write-Host "  설치 완료. 재부팅 후 이 스크립트를 -SkipWSLInstall 으로 다시 실행하세요." -ForegroundColor Yellow
            exit 0
        }
    } catch {
        Write-Host "  WSL 미설치. 실행: wsl --install -d Ubuntu" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Step 1 "WSL 설치 건너뜀 (-SkipWSLInstall)"
}

# === Phase 2: WSL 내부 환경 세팅 ===
Write-Step 2 "WSL 패키지 설치 (tmux, python3, pip)..."

$wslSetup = @'
#!/bin/bash
set -e

echo "[WSL] 패키지 업데이트..."
sudo apt-get update -qq

echo "[WSL] tmux 설치..."
sudo apt-get install -y -qq tmux

echo "[WSL] Python3 + pip 설치..."
sudo apt-get install -y -qq python3 python3-pip python3-venv

echo "[WSL] jq 설치 (JSON 파싱용)..."
sudo apt-get install -y -qq jq

echo "[WSL] 설치 완료"
tmux -V
python3 --version
'@

$wslSetup | wsl bash

# === Phase 3: Telegram Bot 디렉토리 구성 ===
Write-Step 3 "Telegram Bot 환경 구성..."

$botSetup = @'
#!/bin/bash
set -e

BOT_DIR="$HOME/telegram-bot"
mkdir -p "$BOT_DIR"

# Python 가상환경
if [ ! -d "$BOT_DIR/venv" ]; then
    echo "[BOT] 가상환경 생성..."
    python3 -m venv "$BOT_DIR/venv"
fi

echo "[BOT] 의존성 설치..."
source "$BOT_DIR/venv/bin/activate"
pip install -q python-telegram-bot==20.7

echo "[BOT] 디렉토리 구조 생성..."
mkdir -p "$BOT_DIR/downloads"
mkdir -p "$BOT_DIR/uploads"

# /mnt/d 심볼릭 링크 (편의용)
if [ -d "/mnt/d" ] && [ ! -L "$BOT_DIR/d-drive" ]; then
    ln -s /mnt/d "$BOT_DIR/d-drive"
    echo "[BOT] /mnt/d 링크 생성"
fi

echo "[BOT] 환경 준비 완료: $BOT_DIR"
ls -la "$BOT_DIR/"
'@

$botSetup | wsl bash

# === Phase 4: Telegram Bot 코드 배포 ===
Write-Step 4 "Telegram Bot 코드 배포..."

# 이 레포의 scripts/telegram-bot.py를 WSL로 복사
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$botPySource = Join-Path $scriptDir "telegram-bot.py"
$botConfigSource = Join-Path $scriptDir "telegram-bot-config.json"

if (Test-Path $botPySource) {
    $wslPath = wsl wslpath -u ($botPySource -replace "\\", "/") 2>&1
    wsl bash -c "cp '$wslPath' ~/telegram-bot/bot.py" 2>&1
    Write-Host "  bot.py 배포 완료" -ForegroundColor Green
} else {
    Write-Host "  [WARN] telegram-bot.py 없음 — 수동 배포 필요" -ForegroundColor Yellow
}

if (Test-Path $botConfigSource) {
    $wslPath = wsl wslpath -u ($botConfigSource -replace "\\", "/") 2>&1
    wsl bash -c "cp '$wslPath' ~/telegram-bot/config.json" 2>&1
    Write-Host "  config.json 배포 완료" -ForegroundColor Green
} else {
    Write-Host "  [WARN] telegram-bot-config.json 없음 — 수동 배포 필요" -ForegroundColor Yellow
}

# === Phase 5: tmux 설정 파일 ===
Write-Step 5 "tmux 설정..."

$tmuxConf = @'
#!/bin/bash
cat > ~/.tmux.conf << 'TMUXCONF'
# Park 워크플로우용 tmux 설정

# 마우스 지원 (Termux에서도 터치로 창 전환)
set -g mouse on

# 상태바
set -g status-bg colour235
set -g status-fg colour136
set -g status-left "#[fg=green]#S "
set -g status-right "#[fg=yellow]%H:%M #[fg=cyan]%Y-%m-%d"

# 창 번호 1부터 시작
set -g base-index 1
setw -g pane-base-index 1

# 히스토리 버퍼 늘림
set -g history-limit 50000

# 창 이름 자동 변경
setw -g automatic-rename on

# 256색 지원
set -g default-terminal "screen-256color"

# 빠른 ESC 응답 (SSH 원격 시 중요)
set -sg escape-time 10
TMUXCONF

echo "[TMUX] ~/.tmux.conf 생성 완료"
'@

$tmuxConf | wsl bash

# === 완료 ===
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  WSL 환경 세팅 완료!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "tmux 사용법:" -ForegroundColor White
Write-Host "  wsl" -ForegroundColor Yellow
Write-Host "  tmux new -s work" -ForegroundColor Yellow
Write-Host "  Ctrl+b c  = 새 창" -ForegroundColor Yellow
Write-Host "  Ctrl+b 0~9 = 창 전환" -ForegroundColor Yellow
Write-Host "  Ctrl+b d  = 분리 (세션 유지)" -ForegroundColor Yellow
Write-Host ""
Write-Host "Telegram Bot:" -ForegroundColor White
Write-Host "  wsl" -ForegroundColor Yellow
Write-Host "  cd ~/telegram-bot" -ForegroundColor Yellow
Write-Host "  source venv/bin/activate" -ForegroundColor Yellow
Write-Host '  export BOT_TOKEN="your-token-here"' -ForegroundColor Yellow
Write-Host "  python bot.py" -ForegroundColor Yellow
Write-Host ""
Write-Host "검증:" -ForegroundColor White
Write-Host "  powershell -File scripts/setup-wsl.ps1 -Verify" -ForegroundColor Yellow
Write-Host ""
