# === Jalankan ulang dengan hak Admin jika belum ===
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
    [Security.Principal.WindowsBuiltInRole] "Administrator"))
{
    Start-Process powershell "-ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# === Minimize Semua Jendela ===
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class Win32 {
  [DllImport("user32.dll")]
  public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);
  [DllImport("user32.dll")]
  public static extern bool EnumWindows(Func<IntPtr, int, bool> enumFunc, int lParam);
  [DllImport("user32.dll")]
  public static extern bool IsWindowVisible(IntPtr hWnd);
}
"@

$SW_MINIMIZE = 6
$null = [Win32]::EnumWindows({ param($hWnd, $lParam)
    if ([Win32]::IsWindowVisible($hWnd)) {
        [Win32]::ShowWindowAsync($hWnd, $SW_MINIMIZE) | Out-Null
    }
    return $true
}, 0)
