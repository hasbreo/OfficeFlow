param([Parameter(Mandatory=$true)][int]$ProcessId,[Parameter(Mandatory=$true)][string]$Destination)
$ErrorActionPreference='Stop'
Add-Type -AssemblyName UIAutomationClient,UIAutomationTypes,System.Windows.Forms
Add-Type @'
using System;
using System.Runtime.InteropServices;
public static class OfficeFlowSaveTest {
 [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr window);
}
'@
$condition=New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::ProcessIdProperty,$ProcessId)
$deadline=(Get-Date).AddSeconds(45)
while((Get-Date) -lt $deadline){
 $windows=[System.Windows.Automation.AutomationElement]::RootElement.FindAll([System.Windows.Automation.TreeScope]::Children,$condition)
 foreach($window in $windows){
  if($window.Current.Name -ne 'Save As'){continue}
  $window.SetFocus()
  [void][OfficeFlowSaveTest]::SetForegroundWindow([IntPtr]$window.Current.NativeWindowHandle)
  [System.Windows.Forms.Clipboard]::SetText($Destination)
  [System.Windows.Forms.SendKeys]::SendWait('%n')
  [System.Windows.Forms.SendKeys]::SendWait('^a')
  [System.Windows.Forms.SendKeys]::SendWait('^v')
  [System.Windows.Forms.SendKeys]::SendWait('{ENTER}')
  $saved=(Get-Date).AddSeconds(15)
  while((Get-Date) -lt $saved){if(Test-Path -LiteralPath $Destination){Write-Host 'Native PDF save dialog accepted';exit 0};Start-Sleep -Milliseconds 200}
  throw 'Save dialog did not write the requested PDF'
 }
 Start-Sleep -Milliseconds 250
}
throw 'Native PDF save dialog was not found'
