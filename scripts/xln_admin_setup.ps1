# XLN Online Installer — 관리자 1회 셋업 스크립트
# 목적: XLN Online Installer 자기 자신 업데이트 루프 영구 차단
#
# 배경:
#   XLN 인스톨러는 실행 시 C:\Program Files\XLN Audio\XLN Online Installer\
#   에 자기 자신이 설치되어 있는지 확인한다.
#   해당 디렉토리가 없으면 → 자기 업데이트 시도 → UAC 요청 → 루프
#   이 스크립트는 해당 디렉토리와 exe를 미리 생성해 루프를 차단한다.
#
# 사용법:
#   PowerShell을 "관리자 권한으로 실행" → 이 스크립트 실행
#   scripts\xln_admin_setup.ps1
#
# 1회만 실행하면 영구 적용. 이후 XLN 인스톨러는 자기 업데이트 없이
# 바로 Product List (Addictive Keys 등) 로 진입함.

param(
    [string]$XlnMainDir = "C:\Users\dtsli\XLN_MAIN"
)

$ErrorActionPreference = "Stop"

Write-Host "=== XLN Admin Setup ===" -ForegroundColor Cyan

# 관리자 권한 확인
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")
if (-not $isAdmin) {
    Write-Host "[ERROR] 관리자 권한 필요. PowerShell을 '관리자 권한으로 실행'하세요." -ForegroundColor Red
    exit 1
}
Write-Host "[OK] 관리자 권한 확인됨" -ForegroundColor Green

# 설치할 대상 경로
$targetDir = "C:\Program Files\XLN Audio\XLN Online Installer"
$targetExe = "$targetDir\XLN Online Installer.exe"

# 소스 경로 (이미 다운로드된 바이너리)
$sourcePaths = @(
    "C:\ProgramData\XLN Audio\Temp\App\Cotton XLN Online Installer\updateBinary\XLN Online Installer.exe",
    "$XlnMainDir\installData\installData_prg\XLN Online Installer.exe"
)

$sourceExe = $null
foreach ($src in $sourcePaths) {
    if (Test-Path $src) {
        $sourceExe = $src
        Write-Host "[OK] 소스 발견: $src ($('{0:N1}' -f ((Get-Item $src).Length / 1MB)) MB)" -ForegroundColor Green
        break
    }
}

if (-not $sourceExe) {
    Write-Host "[ERROR] 소스 XLN Online Installer.exe 를 찾을 수 없습니다." -ForegroundColor Red
    Write-Host "       XLN 인스톨러를 한 번 실행해서 다운로드를 완료시키세요." -ForegroundColor Yellow
    exit 1
}

# 이미 설치되어 있으면 스킵
if (Test-Path $targetExe) {
    Write-Host "[SKIP] 이미 설치됨: $targetExe" -ForegroundColor Yellow
    Write-Host "       XLN 인스톨러를 그냥 실행하면 됩니다." -ForegroundColor Yellow
    exit 0
}

# 디렉토리 생성
Write-Host "디렉토리 생성: $targetDir"
New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
Write-Host "[OK] 디렉토리 생성됨" -ForegroundColor Green

# exe 복사
Write-Host "exe 복사 중... (60MB, 잠시 대기)"
Copy-Item -Path $sourceExe -Destination $targetExe -Force
Write-Host "[OK] exe 복사 완료: $targetExe" -ForegroundColor Green

# 버전 파일도 복사 (있으면)
$sourceVersionDir = Split-Path $sourceExe
$versionFile = Join-Path $sourceVersionDir "XLN Online Installer.version"
if (-not (Test-Path $versionFile)) {
    # installData_app 에서 찾기
    $versionFile = "$XlnMainDir\installData\installData_app\XLN Online Installer\XLN Online Installer.version"
}
if (Test-Path $versionFile) {
    Copy-Item -Path $versionFile -Destination "$targetDir\XLN Online Installer.version" -Force
    Write-Host "[OK] 버전 파일 복사됨" -ForegroundColor Green
}

Write-Host ""
Write-Host "=== 완료 ===" -ForegroundColor Green
Write-Host "이제 XLN Online Installer를 실행하면 자기 업데이트 루프 없이" -ForegroundColor White
Write-Host "바로 Product List (Addictive Keys 등) 로 진입합니다." -ForegroundColor White
Write-Host ""
Write-Host "실행: $XlnMainDir\XLN Online Installer.exe" -ForegroundColor Cyan
