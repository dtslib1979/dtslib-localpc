# REAPER WM_COMMAND 헬퍼 (Python에서 호출)
# PowerShell Add-Type으로 WinAPI 래퍼 제공

Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public class WinAPI {
    [DllImport("user32.dll", SetLastError = true)]
    public static extern IntPtr FindWindow(string lpClassName, string lpWindowName);

    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool SetForegroundWindow(IntPtr hWnd);

    [DllImport("user32.dll", SetLastError = true)]
    public static extern IntPtr SendMessage(IntPtr hWnd, uint msg, int wParam, int lParam);

    // WM_COMMAND = 0x0111
    public const uint WM_COMMAND = 0x0111;
}
"@

# REAPER 창 찾기 및 포커싱
function Invoke-REAPERAction {
    param(
        [int]$ActionId
    )

    try {
        # REAPER 프로세스 찾기
        $proc = Get-Process reaper -EA SilentlyContinue | Select-Object -First 1
        if (-not $proc) {
            Write-Host "❌ REAPER 프로세스 없음"
            return $false
        }

        $hwnd = $proc.MainWindowHandle
        Write-Host "✅ REAPER HWND: 0x$($hwnd.ToString('X8'))"

        # 포커스
        [WinAPI]::SetForegroundWindow($hwnd) | Out-Null

        # action 전송
        [WinAPI]::SendMessage($hwnd, [WinAPI]::WM_COMMAND, $ActionId, 0) | Out-Null

        Write-Host "✅ Action $ActionId sent"
        return $true
    }
    catch {
        Write-Host "❌ 실패: $_"
        return $false
    }
}

# 테스트 실행
Write-Host "REAPER 액션 헬퍼 로드 완료"
