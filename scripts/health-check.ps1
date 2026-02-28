# DTSLIB Health Check Script v1.2
# 전체 시스템 상태 점검
# 이관: D:\_SYSTEM\scripts\health-check.ps1 → dtslib-localpc/scripts/health-check.ps1
# Task Scheduler: DTSLIB_HealthCheck (매일 09:00)

$GITHUB_ROOT = "D:\1_GITHUB"

Write-Host "`n========== DTSLIB HEALTH CHECK ==========" -ForegroundColor Cyan
Write-Host "Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n"

# 1. 디스크 용량
Write-Host "[1] DISK USAGE" -ForegroundColor Yellow
$disk = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='D:'"
$totalGB = [math]::Round($disk.Size / 1GB, 2)
$freeGB = [math]::Round($disk.FreeSpace / 1GB, 2)
$usedGB = $totalGB - $freeGB
$usedPercent = [math]::Round(($usedGB / $totalGB) * 100, 1)
Write-Host "    Total: ${totalGB}GB | Used: ${usedGB}GB ($usedPercent%) | Free: ${freeGB}GB"

if ($usedPercent -gt 90) {
    Write-Host "    WARNING: Disk usage over 90%!" -ForegroundColor Red
} elseif ($usedPercent -gt 80) {
    Write-Host "    NOTICE: Disk usage over 80%" -ForegroundColor Yellow
} else {
    Write-Host "    OK" -ForegroundColor Green
}

# 2. GitHub 레포 상태
Write-Host "`n[2] GITHUB REPOS STATUS" -ForegroundColor Yellow
$repos = Get-ChildItem -Path $GITHUB_ROOT -Directory -ErrorAction SilentlyContinue | Where-Object { Test-Path "$($_.FullName)\.git" }
$totalRepos = $repos.Count
$dirtyRepos = @()
$behindRepos = @()
$errorRepos = @()

foreach ($repo in $repos) {
    Push-Location $repo.FullName

    try {
        # Status 확인
        $status = git status --porcelain 2>&1
        if ($LASTEXITCODE -ne 0) {
            $errorRepos += $repo.Name
            Pop-Location
            continue
        }

        if ($status -and $status -notmatch "^fatal") {
            $dirtyRepos += $repo.Name
        }

        # Fetch (에러 무시)
        git fetch origin 2>&1 | Out-Null

        # Behind 체크
        $behindOutput = git rev-list HEAD..origin/main --count 2>&1
        if ($LASTEXITCODE -eq 0 -and $behindOutput -match '^\d+$') {
            $behind = [int]$behindOutput
            if ($behind -gt 0) { $behindRepos += $repo.Name }
        }
    } catch {
        $errorRepos += $repo.Name
    }

    Pop-Location
}

Write-Host "    Total Repos: $totalRepos"
Write-Host "    Clean: $($totalRepos - $dirtyRepos.Count - $errorRepos.Count) | Dirty: $($dirtyRepos.Count) | Behind: $($behindRepos.Count) | Error: $($errorRepos.Count)"

if ($dirtyRepos.Count -gt 0) {
    Write-Host "    Uncommitted: $($dirtyRepos -join ', ')" -ForegroundColor Yellow
}
if ($behindRepos.Count -gt 0) {
    Write-Host "    Need pull: $($behindRepos -join ', ')" -ForegroundColor Yellow
}
if ($errorRepos.Count -gt 0) {
    Write-Host "    Errors: $($errorRepos -join ', ')" -ForegroundColor Red
}

# 3. 폴더 구조 검증
Write-Host "`n[3] FOLDER STRUCTURE" -ForegroundColor Yellow
$requiredDirs = @("D:\1_GITHUB", "D:\2_WORKSPACE", "D:\3_APK", "D:\4_ARCHIVE", "D:\5_YOUTUBE", "D:\_SYSTEM", "D:\_TOOLS")

foreach ($dir in $requiredDirs) {
    if (Test-Path $dir) {
        $itemCount = (Get-ChildItem -Path $dir -ErrorAction SilentlyContinue | Measure-Object).Count
        Write-Host "    [OK] $dir ($itemCount items)" -ForegroundColor Green
    } else {
        Write-Host "    [MISSING] $dir" -ForegroundColor Red
    }
}

# 4. 최근 동기화 로그
Write-Host "`n[4] RECENT SYNC LOGS" -ForegroundColor Yellow
$logDir = "D:\_SYSTEM\logs"
if (Test-Path $logDir) {
    $recentLogs = Get-ChildItem -Path $logDir -Filter "sync_*.log" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 3
    if ($recentLogs) {
        foreach ($log in $recentLogs) {
            Write-Host "    $($log.Name) - $($log.LastWriteTime)"
        }
    } else {
        Write-Host "    No sync logs yet (run sync-all.ps1 first)" -ForegroundColor Gray
    }
} else {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    Write-Host "    Log directory created" -ForegroundColor Gray
}

# 5. _HOMEWORK 체크
Write-Host "`n[5] HOMEWORK STATUS" -ForegroundColor Yellow
$homeworkDir = "D:\_HOMEWORK"
if (Test-Path $homeworkDir) {
    $hwItems = Get-ChildItem -Path $homeworkDir -Directory -ErrorAction SilentlyContinue
    $hwSize = (Get-ChildItem -Path $homeworkDir -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1GB
    Write-Host "    Pending folders: $($hwItems.Count) (~$([math]::Round($hwSize, 1))GB)" -ForegroundColor Yellow
    foreach ($item in $hwItems) {
        Write-Host "      - $($item.Name)" -ForegroundColor Gray
    }
} else {
    Write-Host "    No homework pending" -ForegroundColor Green
}

Write-Host "`n========== HEALTH CHECK COMPLETE ==========`n" -ForegroundColor Cyan
