param(
    [Parameter(Position=0)][string]$Message,
    [Parameter()][string]$Title = "",
    [Parameter()][switch]$Silent = $false
)

# Windows Claude Code 전용 텔레그램 리포터
$BOT_TOKEN = "8621929617:AAH-XpVJ4PKVJV8m9-qB2aLupMHO0nYfZLQ"
$CHAT_ID = "6858098283"

# 시스템 정보
$hostname = $env:COMPUTERNAME
$timestamp = (Get-Date).ToString("MM-dd HH:mm")
$wslStatus = "unknown"
try {
    $wslCheck = wsl -d Ubuntu -u dtsli -- echo OK 2>$null
    if ($wslCheck -match "OK") { $wslStatus = "online" } else { $wslStatus = "offline" }
} catch { $wslStatus = "error" }

# 메시지 본문
$bodyLines = @()
$bodyLines += "[Windows CC] $hostname @ $timestamp"
if ($Title) { $bodyLines += "--- $Title ---" }
$bodyLines += ""
$bodyLines += $Message
$bodyLines += ""
$bodyLines += "WSL: $wslStatus"
$bodyText = $bodyLines -join "`n"

# JSON 수동 조립 → UTF-8 전송
$json = "{`"chat_id`":`"$CHAT_ID`",`"text`":`"$($bodyText.Replace('\','\\').Replace('"','\"').Replace("`n",'\n').Replace("`r",''))`"}"

$uri = "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage"
$bytes = [System.Text.Encoding]::UTF8.GetBytes($json)

try {
    $webRequest = [System.Net.WebRequest]::Create($uri)
    $webRequest.Method = "POST"
    $webRequest.ContentType = "application/json"
    $webRequest.ContentLength = $bytes.Length
    $requestStream = $webRequest.GetRequestStream()
    $requestStream.Write($bytes, 0, $bytes.Length)
    $requestStream.Close()
    $response = $webRequest.GetResponse()
    $reader = New-Object System.IO.StreamReader($response.GetResponseStream())
    $result = $reader.ReadToEnd()
    Write-Host "OK: Telegram sent" -ForegroundColor Green
} catch {
    Write-Host "FAIL: $_" -ForegroundColor Red
}
