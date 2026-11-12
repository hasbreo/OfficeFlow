param([Parameter(Mandatory=$true)][int]$ProcessId)
$ErrorActionPreference='Stop'
Add-Type @'
using System;
using System.Runtime.InteropServices;
public static class OfficeFlowTestWindow {
 [DllImport("user32.dll")] public static extern bool PostMessage(IntPtr window,uint message,IntPtr wp,IntPtr lp);
}
'@
$process=Get-Process -Id $ProcessId
if($process.MainWindowHandle -eq 0){throw 'Native editor has no main window'}
if(-not [OfficeFlowTestWindow]::PostMessage($process.MainWindowHandle,0x10,[IntPtr]::Zero,[IntPtr]::Zero)){throw 'Close request failed'}
