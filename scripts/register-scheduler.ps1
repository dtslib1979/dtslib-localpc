# DTSLIB Task Scheduler Registration v1.2
# 자동화 작업 스케줄러 등록
# 이관: D:\_SYSTEM\scripts\register-scheduler.ps1 → dtslib-localpc/scripts/register-scheduler.ps1
# 경로: 모두 dtslib-localpc/scripts/ 기준

$scriptPath = "D:\PARKSY\dtslib-localpc\scripts"

Write-Host "========== DTSLIB Scheduler Setup ==========" -ForegroundColor Cyan

# 1. 매일 오전 9시 - Health Check
$action1 = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$scriptPath\health-check.ps1`" > `"D:\_SYSTEM\logs\health_$(Get-Date -Format 'yyyyMMdd').log`""
$trigger1 = New-ScheduledTaskTrigger -Daily -At 9am
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

try {
    Register-ScheduledTask -TaskName "DTSLIB_HealthCheck" -Action $action1 -Trigger $trigger1 -Settings $settings -Description "Daily health check at 9am" -Force
    Write-Host "[OK] DTSLIB_HealthCheck - Daily 9:00 AM" -ForegroundColor Green
} catch {
    Write-Host "[FAIL] DTSLIB_HealthCheck: $_" -ForegroundColor Red
}

# 2. 매일 저녁 6시 - Sync All Repos
$action2 = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$scriptPath\sync-all.ps1`""
$trigger2 = New-ScheduledTaskTrigger -Daily -At 6pm

try {
    Register-ScheduledTask -TaskName "DTSLIB_SyncAll" -Action $action2 -Trigger $trigger2 -Settings $settings -Description "Daily repo sync at 6pm" -Force
    Write-Host "[OK] DTSLIB_SyncAll - Daily 6:00 PM" -ForegroundColor Green
} catch {
    Write-Host "[FAIL] DTSLIB_SyncAll: $_" -ForegroundColor Red
}

# 3. USB 연결 시 - Dashboard 열기 (이벤트 기반은 복잡해서 로그온 시로 대체)
$action3 = New-ScheduledTaskAction -Execute "cmd.exe" -Argument "/c start `"`" `"D:\_SYSTEM\dashboard\index.html`""
$trigger3 = New-ScheduledTaskTrigger -AtLogOn
$principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive

try {
    Register-ScheduledTask -TaskName "DTSLIB_Dashboard" -Action $action3 -Trigger $trigger3 -Principal $principal -Settings $settings -Description "Open dashboard at logon" -Force
    Write-Host "[OK] DTSLIB_Dashboard - At Logon" -ForegroundColor Green
} catch {
    Write-Host "[FAIL] DTSLIB_Dashboard: $_" -ForegroundColor Red
}

Write-Host "`n========== Registered Tasks ==========" -ForegroundColor Cyan
Get-ScheduledTask | Where-Object { $_.TaskName -like "DTSLIB_*" } | Format-Table TaskName, State, @{N='Trigger';E={$_.Triggers.StartBoundary}}

Write-Host "`nTo remove all DTSLIB tasks:" -ForegroundColor Gray
Write-Host "  Get-ScheduledTask | Where-Object { `$_.TaskName -like 'DTSLIB_*' } | Unregister-ScheduledTask -Confirm:`$false"
