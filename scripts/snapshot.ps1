# DTSLIB Control Tower — Snapshot Refresh Script
# 원클릭으로 모든 스냅샷 갱신
# Usage: powershell -ExecutionPolicy Bypass -File snapshot.ps1 [-AutoCommit]

param(
    [switch]$AutoCommit = $false
)

$ErrorActionPreference = "Continue"
$repoRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$snapshotDir = Join-Path $repoRoot "snapshots"
$reposDir = Join-Path $repoRoot "repos"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  DTSLIB Control Tower - Snapshot Refresh" -ForegroundColor Cyan
Write-Host "  $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Ensure directories exist
New-Item -ItemType Directory -Path $snapshotDir -Force -ErrorAction SilentlyContinue | Out-Null
New-Item -ItemType Directory -Path $reposDir -Force -ErrorAction SilentlyContinue | Out-Null

$timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:sszzz"

# ─────────────────────────────────────
# 1. D: Drive Tree (depth 3, dirs only)
# ─────────────────────────────────────
Write-Host "[1/4] D: Drive Tree..." -ForegroundColor Yellow
$tree = @()
Get-ChildItem -Path 'D:\' -Directory -ErrorAction SilentlyContinue | ForEach-Object {
    $tree += "D:\$($_.Name)\"
    Get-ChildItem -Path $_.FullName -Directory -ErrorAction SilentlyContinue | ForEach-Object {
        $tree += "  $($_.Name)\"
        Get-ChildItem -Path $_.FullName -Directory -ErrorAction SilentlyContinue | Select-Object -First 30 | ForEach-Object {
            $tree += "    $($_.Name)\"
        }
    }
}
$tree | Out-File -FilePath (Join-Path $snapshotDir "drive-d.txt") -Encoding UTF8
Write-Host "  OK: $($tree.Count) entries" -ForegroundColor Green

# ─────────────────────────────────────
# 2. Environment Versions
# ─────────────────────────────────────
Write-Host "[2/4] Environment Versions..." -ForegroundColor Yellow
$nodeVer = try { (& node --version 2>&1).ToString() -replace '^v','' } catch { "not installed" }
$npmVer = try { (& npm --version 2>&1).ToString() } catch { "not installed" }
$pyVer = try { (& python --version 2>&1).ToString() -replace '^Python ','' } catch { "not installed" }
$gitVer = try { (& git --version 2>&1).ToString() -replace '^git version ','' } catch { "not installed" }
$javaVer = try { (& java -version 2>&1 | Select-Object -First 1).ToString() } catch { "not installed" }
$psVer = $PSVersionTable.PSVersion.ToString()
$goVer = try { (& go version 2>&1).ToString() -replace '^go version go','' -replace ' .*$','' } catch { "not installed" }
$ffmpegVer = try { (& ffmpeg -version 2>&1 | Select-Object -First 1).ToString() -replace '^ffmpeg version ','' -replace ' .*$','' } catch { "not installed" }
$rcloneVer = try { (& rclone version 2>&1 | Select-Object -First 1).ToString() -replace '^rclone v','' } catch { "not installed" }

$envData = @{
    "collected" = $timestamp
    "node" = $nodeVer
    "npm" = $npmVer
    "python" = $pyVer
    "git" = $gitVer
    "java" = $javaVer
    "powershell" = $psVer
    "go" = $goVer
    "ffmpeg" = $ffmpegVer
    "rclone" = $rcloneVer
}
$envData | ConvertTo-Json -Depth 3 | Out-File -FilePath (Join-Path $snapshotDir "env-versions.json") -Encoding UTF8
Write-Host "  OK: $($envData.Count) tools" -ForegroundColor Green

# ─────────────────────────────────────
# 3. Installed Software (winget)
# ─────────────────────────────────────
Write-Host "[3/4] Installed Software..." -ForegroundColor Yellow
$software = @()
try {
    $rawOutput = & winget list --accept-source-agreements 2>&1
    $started = $false
    foreach ($line in $rawOutput) {
        $lineStr = $line.ToString()
        if ($lineStr -match '^-{5,}') { $started = $true; continue }
        if ($started -and $lineStr.Trim().Length -gt 3) {
            $software += $lineStr.Trim()
        }
    }
} catch {}
$swObj = @{ "collected" = $timestamp; "count" = $software.Count; "packages" = $software }
$swObj | ConvertTo-Json -Depth 3 | Out-File -FilePath (Join-Path $snapshotDir "installed-software.json") -Encoding UTF8
Write-Host "  OK: $($software.Count) packages" -ForegroundColor Green

# ─────────────────────────────────────
# 5. Cross-Repo Status (3 production repos)
# ─────────────────────────────────────
Write-Host "[4/4] Cross-Repo Status..." -ForegroundColor Yellow

$repoPaths = @{
    "parksy-audio" = "D:\PARKSY\parksy-audio"
    "parksy-image" = "D:\parksy-image"
    "dtslib-apk-lab" = "D:\1_GITHUB\dtslib-apk-lab"
}

$repoStatus = @{}
foreach ($name in $repoPaths.Keys) {
    $path = $repoPaths[$name]
    if (Test-Path (Join-Path $path ".git")) {
        Push-Location $path
        $commitHash = (& git log --oneline -1 2>&1).ToString()
        $branch = (& git branch --show-current 2>&1).ToString()
        $dirtyCount = @(& git status --porcelain 2>&1 | Where-Object { $_.ToString().Trim().Length -gt 0 }).Count
        Pop-Location

        $repoStatus[$name] = @{
            "local_path" = $path
            "branch" = $branch
            "last_commit" = $commitHash
            "dirty_files" = $dirtyCount
        }
        Write-Host "  $name : $branch, dirty=$dirtyCount" -ForegroundColor Gray
    } else {
        $repoStatus[$name] = @{ "local_path" = $path; "error" = "not found" }
        Write-Host "  $name : NOT FOUND at $path" -ForegroundColor Red
    }
}

$statusObj = @{
    "updated" = $timestamp
    "repos" = $repoStatus
}
$statusObj | ConvertTo-Json -Depth 4 | Out-File -FilePath (Join-Path $reposDir "status.json") -Encoding UTF8
Write-Host "  OK: $($repoStatus.Count) repos scanned" -ForegroundColor Green

# ─────────────────────────────────────
# Auto-Commit (optional)
# ─────────────────────────────────────
if ($AutoCommit) {
    Write-Host ""
    Write-Host "[GIT] Auto-committing snapshot..." -ForegroundColor Yellow
    Push-Location $repoRoot
    & git add snapshots/ repos/status.json
    & git commit -m "chore: auto-update snapshots $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
    & git push
    Pop-Location
    Write-Host "  OK: Committed and pushed" -ForegroundColor Green
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  Snapshot refresh complete!" -ForegroundColor Green
Write-Host "  Files: $snapshotDir" -ForegroundColor Gray
Write-Host "  Repos: $reposDir\status.json" -ForegroundColor Gray
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
