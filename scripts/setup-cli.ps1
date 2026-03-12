# setup-cli.ps1 — Claude Code CLI + MCP 서버 자동 설치
# 용도: Claude Desktop GUI → CLI 전환. MCP 포함 원스톱 설치.
# 실행: powershell -ExecutionPolicy Bypass -File scripts/setup-cli.ps1

param(
    [switch]$SkipMCP,       # MCP 설치 생략
    [switch]$Verify         # 설치 확인만
)

$ErrorActionPreference = "Continue"

function Write-Step($num, $msg) {
    Write-Host "`n[$num] $msg" -ForegroundColor Cyan
}

function Test-Command($cmd) {
    try {
        $null = & $cmd --version 2>&1
        return $true
    } catch {
        return $false
    }
}

# === 검증 모드 ===
if ($Verify) {
    Write-Host "`n=== CLI 인프라 검증 ===" -ForegroundColor Cyan
    $results = @()

    # Node.js
    if (Test-Command "node") {
        $ver = (node --version 2>&1).ToString().Trim()
        $results += [PSCustomObject]@{Item="Node.js"; Status="OK"; Detail=$ver}
    } else {
        $results += [PSCustomObject]@{Item="Node.js"; Status="MISSING"; Detail="npm install 불가"}
    }

    # npm
    if (Test-Command "npm") {
        $ver = (npm --version 2>&1).ToString().Trim()
        $results += [PSCustomObject]@{Item="npm"; Status="OK"; Detail=$ver}
    } else {
        $results += [PSCustomObject]@{Item="npm"; Status="MISSING"; Detail=""}
    }

    # Claude Code CLI
    $claudePath = npm list -g @anthropic-ai/claude-code 2>&1
    if ($claudePath -match "claude-code@") {
        $ver = ($claudePath | Select-String "claude-code@(.+)$").Matches.Groups[1].Value
        $results += [PSCustomObject]@{Item="Claude Code CLI"; Status="OK"; Detail="v$ver"}
    } else {
        $results += [PSCustomObject]@{Item="Claude Code CLI"; Status="MISSING"; Detail="setup-cli.ps1 실행 필요"}
    }

    # Claude 실행 가능 여부
    if (Test-Command "claude") {
        $results += [PSCustomObject]@{Item="claude 명령어"; Status="OK"; Detail="실행 가능"}
    } else {
        $results += [PSCustomObject]@{Item="claude 명령어"; Status="MISSING"; Detail="PATH 확인"}
    }

    $results | Format-Table -AutoSize
    $missing = ($results | Where-Object Status -eq "MISSING").Count
    if ($missing -eq 0) {
        Write-Host "모든 항목 OK" -ForegroundColor Green
    } else {
        Write-Host "$missing 개 항목 누락" -ForegroundColor Red
    }
    exit 0
}

# === Phase 1: Node.js 확인 ===
Write-Step 1 "Node.js 확인..."

if (Test-Command "node") {
    $nodeVer = (node --version 2>&1).ToString().Trim()
    $major = [int]($nodeVer -replace "^v(\d+)\..*", '$1')
    if ($major -ge 18) {
        Write-Host "  Node.js $nodeVer (OK)" -ForegroundColor Green
    } else {
        Write-Host "  Node.js $nodeVer — 18+ 필요. 업그레이드:" -ForegroundColor Red
        Write-Host "  winget install OpenJS.NodeJS.22" -ForegroundColor Yellow
        exit 1
    }
} else {
    Write-Host "  Node.js 미설치. 설치:" -ForegroundColor Red
    Write-Host "  winget install OpenJS.NodeJS.22" -ForegroundColor Yellow
    exit 1
}

# === Phase 2: Claude Code CLI 설치 ===
Write-Step 2 "Claude Code CLI 설치..."

$claudeInstalled = npm list -g @anthropic-ai/claude-code 2>&1
if ($claudeInstalled -match "claude-code@") {
    Write-Host "  이미 설치됨 (skip)" -ForegroundColor Green
} else {
    Write-Host "  설치 중..." -ForegroundColor Yellow
    npm install -g @anthropic-ai/claude-code 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  설치 완료" -ForegroundColor Green
    } else {
        Write-Host "  [ERROR] 설치 실패" -ForegroundColor Red
        exit 1
    }
}

# === Phase 3: claude 실행 가능 확인 ===
Write-Step 3 "claude 명령어 확인..."

if (Test-Command "claude") {
    $claudeVer = (claude --version 2>&1).ToString().Trim()
    Write-Host "  claude $claudeVer" -ForegroundColor Green
} else {
    Write-Host "  [WARN] claude 명령어를 찾을 수 없음" -ForegroundColor Yellow
    Write-Host "  터미널 재시작 후 다시 확인하세요" -ForegroundColor Yellow
}

# === Phase 4: MCP 서버 연결 ===
if (-not $SkipMCP) {
    Write-Step 4 "MCP 서버 연결..."

    $mcpServers = @(
        @{
            Name = "puppeteer"
            Desc = "브라우저 자동화 (YouTube, 티스토리 등)"
            Cmd  = "npx"
            Args = @("-y", "puppeteer-mcp-claude", "serve")
        },
        @{
            Name = "github"
            Desc = "GitHub API 연동"
            Cmd  = "npx"
            Args = @("-y", "@modelcontextprotocol/server-github")
        },
        @{
            Name = "filesystem"
            Desc = "파일시스템 MCP"
            Cmd  = "npx"
            Args = @("-y", "@anthropic-ai/mcp-filesystem")
        }
    )

    foreach ($mcp in $mcpServers) {
        Write-Host "  [$($mcp.Name)] $($mcp.Desc)..." -ForegroundColor White
        try {
            $argStr = ($mcp.Args | ForEach-Object { "`"$_`"" }) -join " "
            $fullCmd = "claude mcp add $($mcp.Name) -- $($mcp.Cmd) $argStr"
            Invoke-Expression $fullCmd 2>&1 | Out-Null
            Write-Host "    추가 완료" -ForegroundColor Green
        } catch {
            Write-Host "    [WARN] 수동 추가 필요: claude mcp add $($mcp.Name) -- $($mcp.Cmd) $($mcp.Args -join ' ')" -ForegroundColor Yellow
        }
    }

    Write-Host "`n  MCP 확인: claude 실행 후 /mcp 입력" -ForegroundColor White
} else {
    Write-Host "`n[4] MCP 설치 생략 (-SkipMCP)" -ForegroundColor Gray
}

# === 완료 ===
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Claude Code CLI 설치 완료!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "사용법:" -ForegroundColor White
Write-Host "  claude                    # CLI 시작" -ForegroundColor Yellow
Write-Host "  claude /mcp               # MCP 서버 확인" -ForegroundColor Yellow
Write-Host "  claude mcp list           # MCP 목록" -ForegroundColor Yellow
Write-Host ""
Write-Host "광역 작업 예시:" -ForegroundColor White
Write-Host "  cd D:\PARKSY\parksy-audio" -ForegroundColor Yellow
Write-Host "  claude" -ForegroundColor Yellow
Write-Host '  > "MIDI 렌더링 배치 돌려"' -ForegroundColor Yellow
Write-Host ""
Write-Host "검증:" -ForegroundColor White
Write-Host "  powershell -File scripts/setup-cli.ps1 -Verify" -ForegroundColor Yellow
Write-Host ""
