# DTSLIB GitHub Sync Script v1.2
# 모든 레포지토리 일괄 동기화 (에러 핸들링 개선)
# 이관: D:\_SYSTEM\scripts\sync-all.ps1 → dtslib-localpc/scripts/sync-all.ps1
# Task Scheduler: DTSLIB_SyncAll (매일 18:00)

$GITHUB_ROOT = "D:\1_GITHUB"
$LOG_DIR = "D:\_SYSTEM\logs"
$DATE = Get-Date -Format "yyyy-MM-dd_HH-mm"
$LOG_FILE = "$LOG_DIR\sync_$DATE.log"

# 로그 디렉토리 생성
if (!(Test-Path $LOG_DIR)) { New-Item -ItemType Directory -Path $LOG_DIR -Force | Out-Null }

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "HH:mm:ss"
    $logMessage = "[$timestamp] $Message"
    Write-Host $logMessage
    Add-Content -Path $LOG_FILE -Value $logMessage
}

Write-Log "========== DTSLIB Sync Started =========="

$stats = @{ synced = 0; uptodate = 0; dirty = 0; error = 0 }

# 모든 레포 순회
Get-ChildItem -Path $GITHUB_ROOT -Directory | ForEach-Object {
    $repo = $_.Name
    $repoPath = $_.FullName

    if (Test-Path "$repoPath\.git") {
        Write-Log "Syncing: $repo"

        Push-Location $repoPath

        try {
            # 기본 브랜치 확인
            $defaultBranch = git symbolic-ref refs/remotes/origin/HEAD 2>&1
            if ($LASTEXITCODE -ne 0) {
                # origin/HEAD가 없으면 main 또는 master 시도
                $branches = git branch -r 2>&1
                if ($branches -match "origin/main") {
                    $branch = "main"
                } elseif ($branches -match "origin/master") {
                    $branch = "master"
                } else {
                    Write-Log "  [$repo] No remote branch found - skipping"
                    $stats.error++
                    Pop-Location
                    return
                }
            } else {
                $branch = $defaultBranch -replace "refs/remotes/origin/", ""
            }

            # Fetch
            git fetch origin 2>&1 | Out-Null

            # Status 확인
            $status = git status --porcelain 2>&1
            if ($LASTEXITCODE -ne 0) {
                Write-Log "  [$repo] Git error - skipping"
                $stats.error++
                Pop-Location
                return
            }

            # Behind/Ahead 체크
            $behindOutput = git rev-list "HEAD..origin/$branch" --count 2>&1
            $aheadOutput = git rev-list "origin/$branch..HEAD" --count 2>&1

            $behind = 0
            $ahead = 0
            if ($behindOutput -match '^\d+$') { $behind = [int]$behindOutput }
            if ($aheadOutput -match '^\d+$') { $ahead = [int]$aheadOutput }

            if ($status -and $status -notmatch "^fatal") {
                Write-Log "  [$repo] Local changes detected"
                $stats.dirty++
            }
            if ($behind -gt 0) {
                Write-Log "  [$repo] Behind by $behind - Pulling..."
                git pull origin $branch 2>&1 | Out-Null
                $stats.synced++
            }
            if ($ahead -gt 0) {
                Write-Log "  [$repo] Ahead by $ahead commits"
            }
            if (!$status -and $behind -eq 0) {
                Write-Log "  [$repo] Up to date"
                $stats.uptodate++
            }
        } catch {
            Write-Log "  [$repo] Error: $_"
            $stats.error++
        }

        Pop-Location
    } else {
        Write-Log "  [$repo] Not a git repository - skipping"
    }
}

Write-Log "========== DTSLIB Sync Completed =========="
Write-Log "Stats: Synced=$($stats.synced) | UpToDate=$($stats.uptodate) | Dirty=$($stats.dirty) | Error=$($stats.error)"
Write-Log "Log saved to: $LOG_FILE"
