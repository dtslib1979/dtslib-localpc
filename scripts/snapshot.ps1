# DTSLIB — 로컬 개발 이력 저장소 Snapshot Script
# 원클릭으로 모든 스냅샷 갱신
# 핵심: status.json은 MERGE 방식 (rich metadata 보존, git 정보만 갱신)
#
# Usage: powershell -ExecutionPolicy Bypass -File snapshot.ps1 [-AutoCommit]
# 8 steps: drive tree, env versions, software, vscode, PATH, git config, repo status, staleness

param(
    [switch]$AutoCommit = $false
)

$ErrorActionPreference = "Continue"
$repoRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$snapshotDir = Join-Path $repoRoot "snapshots"
$reposDir = Join-Path $repoRoot "repos"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  DTSLIB Snapshot Refresh" -ForegroundColor Cyan
Write-Host "  $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

New-Item -ItemType Directory -Path $snapshotDir -Force -ErrorAction SilentlyContinue | Out-Null
New-Item -ItemType Directory -Path $reposDir -Force -ErrorAction SilentlyContinue | Out-Null

$timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:sszzz"
$warnings = @()

# ─────────────────────────────────────
# [1/8] D: Drive Tree (depth 3, dirs only)
# ─────────────────────────────────────
Write-Host "[1/8] D: Drive Tree..." -ForegroundColor Yellow
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
# [2/8] Environment Versions
# ─────────────────────────────────────
Write-Host "[2/8] Environment Versions..." -ForegroundColor Yellow
$nodeVer = try { (& node --version 2>&1).ToString() -replace '^v','' } catch { "not installed" }
$npmVer = try { (& npm --version 2>&1).ToString() } catch { "not installed" }
$pyVer = try { (& python --version 2>&1).ToString() -replace '^Python ','' } catch { "not installed" }
$gitVer = try { (& git --version 2>&1).ToString() -replace '^git version ','' } catch { "not installed" }
$javaVer = try { (& java -version 2>&1 | Select-Object -First 1).ToString() } catch { "not installed" }
$psVer = $PSVersionTable.PSVersion.ToString()
$goVer = try { (& go version 2>&1).ToString() -replace '^go version go','' -replace ' .*$','' } catch { "not installed" }
$ffmpegVer = try { (& ffmpeg -version 2>&1 | Select-Object -First 1).ToString() -replace '^ffmpeg version ','' -replace ' .*$','' } catch { "not installed" }
$rcloneVer = try { (& rclone version 2>&1 | Select-Object -First 1).ToString() -replace '^rclone v','' } catch { "not installed" }
$flutterVer = try { (& flutter --version 2>&1 | Select-Object -First 1).ToString() -replace '^Flutter ','' -replace ' .*$','' } catch { "not in PATH" }
$adbVer = try { (& adb version 2>&1 | Select-Object -First 1).ToString() -replace '^Android Debug Bridge version ','' } catch { "not in PATH" }

$envData = [ordered]@{
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
    "flutter" = $flutterVer
    "adb" = $adbVer
}
$envData | ConvertTo-Json -Depth 3 | Out-File -FilePath (Join-Path $snapshotDir "env-versions.json") -Encoding UTF8
Write-Host "  OK: $($envData.Count) tools" -ForegroundColor Green

# ─────────────────────────────────────
# [3/8] Installed Software (winget)
# ─────────────────────────────────────
Write-Host "[3/8] Installed Software..." -ForegroundColor Yellow
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
# [4/8] VSCode Extensions
# ─────────────────────────────────────
Write-Host "[4/8] VSCode Extensions..." -ForegroundColor Yellow
$extensions = @()
try {
    $extensions = @(& code --list-extensions 2>&1 | Where-Object { $_ -notmatch '^(ERROR|WARN)' })
} catch {}
$extObj = @{ "collected" = $timestamp; "count" = $extensions.Count; "extensions" = $extensions }
$extObj | ConvertTo-Json -Depth 3 | Out-File -FilePath (Join-Path $snapshotDir "vscode-extensions.json") -Encoding UTF8
Write-Host "  OK: $($extensions.Count) extensions" -ForegroundColor Green

# ─────────────────────────────────────
# [5/8] PATH & Key Binaries → env/path-settings.json
# ─────────────────────────────────────
Write-Host "[5/8] PATH & Key Binaries..." -ForegroundColor Yellow
$envDir = Join-Path $repoRoot "env"
New-Item -ItemType Directory -Path $envDir -Force -ErrorAction SilentlyContinue | Out-Null

$pathEntries = @($env:Path -split ';' | Where-Object { $_.Trim().Length -gt 0 } | Sort-Object -Unique)
$keyBins = [ordered]@{}
$binChecks = @("node","python","git","go","java","ffmpeg","rclone","code","flutter","adb")
foreach ($bin in $binChecks) {
    $loc = (Get-Command $bin -ErrorAction SilentlyContinue).Source
    $keyBins[$bin] = if ($loc) { $loc } else { "not found" }
}
$pathObj = [ordered]@{
    "collected" = $timestamp
    "note" = "auto-generated by snapshot.ps1"
    "path_entries" = $pathEntries
    "key_binaries" = $keyBins
}
$pathObj | ConvertTo-Json -Depth 3 | Out-File -FilePath (Join-Path $envDir "path-settings.json") -Encoding UTF8
Write-Host "  OK: $($pathEntries.Count) PATH entries, $($binChecks.Count) binaries" -ForegroundColor Green

# ─────────────────────────────────────
# [6/8] Git Config → env/git-config.md
# ─────────────────────────────────────
Write-Host "[6/8] Git Config..." -ForegroundColor Yellow
$gitConfigLines = @()
$gitConfigLines += "# Git Global Config (auto-generated by snapshot.ps1)"
$gitConfigLines += "# Collected: $timestamp"
$gitConfigLines += ""
$gitConfigLines += "## git config --global --list"
$gitConfigLines += '```'
try {
    $gcOutput = & git config --global --list 2>&1
    foreach ($line in $gcOutput) { $gitConfigLines += $line.ToString() }
} catch {
    $gitConfigLines += "(error reading git config)"
}
$gitConfigLines += '```'
$gitConfigLines += ""
$gitConfigLines += "## safe.directory entries"
$gitConfigLines += '```'
try {
    $safeDirs = & git config --global --get-all safe.directory 2>&1
    foreach ($sd in $safeDirs) { $gitConfigLines += $sd.ToString() }
} catch {
    $gitConfigLines += "(none)"
}
$gitConfigLines += '```'
$gitConfigLines += ""
$gitConfigLines += "## SSH key status"
$sshDir = Join-Path $env:USERPROFILE ".ssh"
if (Test-Path $sshDir) {
    $sshFiles = @(Get-ChildItem $sshDir -File -ErrorAction SilentlyContinue | Where-Object { $_.Name -notmatch 'known_hosts|config' })
    if ($sshFiles.Count -gt 0) {
        $gitConfigLines += "Keys found: $($sshFiles.Name -join ', ')"
    } else {
        $gitConfigLines += "No SSH keys found"
    }
} else {
    $gitConfigLines += "~/.ssh directory does not exist"
}
$gitConfigLines | Out-File -FilePath (Join-Path $envDir "git-config.md") -Encoding UTF8
Write-Host "  OK: git config collected" -ForegroundColor Green

# ─────────────────────────────────────
# [7/8] Cross-Repo Status (MERGE — rich metadata 보존)
# ─────────────────────────────────────
Write-Host "[7/8] Cross-Repo Status (merge)..." -ForegroundColor Yellow

$statusFile = Join-Path $reposDir "status.json"

# Read existing status.json to preserve rich metadata (phase, score, queue, cross_links)
$existingJson = $null
if (Test-Path $statusFile) {
    try {
        $existingJson = Get-Content $statusFile -Raw -Encoding UTF8 | ConvertFrom-Json
    } catch {
        Write-Host "  WARN: Could not parse existing status.json" -ForegroundColor Red
        $warnings += "status.json parse failed - rich metadata may be lost"
    }
}

$repoPaths = [ordered]@{
    "parksy-audio" = "D:\PARKSY\parksy-audio"
    "parksy-image" = "D:\parksy-image"
    "dtslib-apk-lab" = "D:\1_GITHUB\dtslib-apk-lab"
}

foreach ($name in $repoPaths.Keys) {
    $path = $repoPaths[$name]
    if (Test-Path (Join-Path $path ".git")) {
        Push-Location $path
        $commitHash = (& git rev-parse --short HEAD 2>&1).ToString()
        $commitMsg = (& git log -1 --format="%s" 2>&1).ToString()
        $branch = (& git branch --show-current 2>&1).ToString()
        $dirtyCount = @(& git status --porcelain 2>&1 | Where-Object { $_.ToString().Trim().Length -gt 0 }).Count
        Pop-Location

        # MERGE: update ONLY git fields, preserve everything else
        if ($existingJson -and $existingJson.repos.PSObject.Properties[$name]) {
            $existingJson.repos.$name.branch = $branch
            $existingJson.repos.$name.last_commit = $commitHash
            $existingJson.repos.$name.last_commit_msg = $commitMsg
            $existingJson.repos.$name.dirty_files = $dirtyCount
        } else {
            Write-Host "  WARN: No existing metadata for $name" -ForegroundColor Red
            $warnings += "$name has no rich metadata in status.json"
        }
        Write-Host "  $name : $branch, $commitHash, dirty=$dirtyCount" -ForegroundColor Gray
    } else {
        Write-Host "  $name : NOT FOUND at $path" -ForegroundColor Red
        $warnings += "$name not found at $path"
    }
}

if ($existingJson) {
    $existingJson.updated = $timestamp
    $existingJson | ConvertTo-Json -Depth 6 | Out-File -FilePath $statusFile -Encoding UTF8
    Write-Host "  OK: $($repoPaths.Count) repos merged (rich metadata preserved)" -ForegroundColor Green
} else {
    Write-Host "  WARN: No existing status.json — create one manually or via Claude session" -ForegroundColor Red
    $warnings += "status.json missing - rich metadata cannot be auto-generated"
}

# ─────────────────────────────────────
# [8/8] Session Log Staleness Check
# ─────────────────────────────────────
Write-Host "[8/8] Session Log Staleness..." -ForegroundColor Yellow

$journals = [ordered]@{
    "parksy-audio" = Join-Path $reposDir "parksy-audio.md"
    "parksy-image" = Join-Path $reposDir "parksy-image.md"
    "dtslib-apk-lab" = Join-Path $reposDir "dtslib-apk-lab.md"
}
$staleDays = 7
$today = Get-Date

foreach ($name in $journals.Keys) {
    $journalPath = $journals[$name]
    if (Test-Path $journalPath) {
        $content = Get-Content $journalPath -Raw
        $dateMatches = [regex]::Matches($content, '### (\d{4}-\d{2}-\d{2})')
        if ($dateMatches.Count -gt 0) {
            $lastDateStr = $dateMatches[$dateMatches.Count - 1].Groups[1].Value
            $lastDate = [datetime]::ParseExact($lastDateStr, 'yyyy-MM-dd', $null)
            $daysSince = ($today - $lastDate).Days
            if ($daysSince -gt $staleDays) {
                Write-Host "  STALE: $name - last log ${daysSince}d ago ($lastDateStr)" -ForegroundColor Red
                $warnings += "$name session log stale (${daysSince}d since $lastDateStr)"
            } else {
                Write-Host "  OK: $name - last log ${daysSince}d ago" -ForegroundColor Green
            }
        } else {
            Write-Host "  WARN: $name - no session logs yet" -ForegroundColor Yellow
        }
    } else {
        Write-Host "  WARN: $name - journal file not found!" -ForegroundColor Red
        $warnings += "$name journal file missing"
    }
}

# ─────────────────────────────────────
# Summary
# ─────────────────────────────────────
Write-Host ""
if ($warnings.Count -gt 0) {
    Write-Host "========================================" -ForegroundColor Yellow
    Write-Host "  Warnings ($($warnings.Count)):" -ForegroundColor Yellow
    foreach ($w in $warnings) {
        Write-Host "  - $w" -ForegroundColor Yellow
    }
    Write-Host "========================================" -ForegroundColor Yellow
} else {
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "  All checks passed!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
}

# ─────────────────────────────────────
# Auto-Commit (optional)
# ─────────────────────────────────────
if ($AutoCommit) {
    Write-Host ""
    Write-Host "[GIT] Auto-committing snapshot..." -ForegroundColor Yellow
    Push-Location $repoRoot
    & git add snapshots/ repos/status.json env/path-settings.json env/git-config.md
    & git commit -m "chore: snapshot auto-update $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
    & git push
    Pop-Location
    Write-Host "  OK: Committed and pushed" -ForegroundColor Green
}

Write-Host ""
Write-Host "Done. $(Get-Date -Format 'HH:mm:ss')" -ForegroundColor Gray
Write-Host ""
