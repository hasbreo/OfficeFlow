param([Parameter(Mandatory=$true)][int]$EditorProcessId)
$ErrorActionPreference='Stop'
Add-Type -AssemblyName UIAutomationClient,UIAutomationTypes
Add-Type @'
using System;
using System.Text;
using System.Collections.Generic;
using System.Runtime.InteropServices;
public static class OfficeFlowPrintTestWindow {
 public delegate bool EnumProc(IntPtr window,IntPtr data);
 [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc callback,IntPtr data);
 [DllImport("user32.dll",CharSet=CharSet.Unicode)] public static extern int GetClassName(IntPtr window,StringBuilder value,int capacity);
 [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr window,out uint process);
 [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr window);
 public static IntPtr[] Dialogs(int process) {
  var result=new List<IntPtr>();
  EnumWindows((window,data)=>{
   uint owner;GetWindowThreadProcessId(window,out owner);
   var name=new StringBuilder(256);GetClassName(window,name,name.Capacity);
   if(owner==process && name.ToString()=="#32770" && IsWindowVisible(window))result.Add(window);
   return true;
  },IntPtr.Zero);
  return result.ToArray();
 }
}
'@
$deadline=(Get-Date).AddSeconds(60)
$helper=$null
while((Get-Date) -lt $deadline){
 $candidate=Get-CimInstance Win32_Process -Filter "Name='PrintPDFAndDelete.exe'" | Where-Object ParentProcessId -eq $EditorProcessId | Select-Object -First 1
 if($candidate){$helper=Get-Process -Id $candidate.ProcessId;break}
 Start-Sleep -Milliseconds 200
}
if(-not $helper){throw 'The native editor did not launch its installed printing helper'}
while((Get-Date) -lt $deadline){
 foreach($handle in [OfficeFlowPrintTestWindow]::Dialogs($helper.Id)){
  $window=[System.Windows.Automation.AutomationElement]::FromHandle($handle)
  if($window.Current.Name -ne 'Print'){continue}
  $cancelCondition=New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::NameProperty,'Cancel')
  $cancel=$window.FindFirst([System.Windows.Automation.TreeScope]::Descendants,$cancelCondition)
  if(-not $cancel){throw 'Windows Print dialog has no Cancel button'}
  $cancel.GetCurrentPattern([System.Windows.Automation.InvokePattern]::Pattern).Invoke()
  if(-not $helper.WaitForExit(15000)){throw 'Printing helper did not exit after Cancel'}
  if($helper.ExitCode -ne 0){throw "Printing helper failed: $($helper.ExitCode)"}
  Write-Host 'Installed native printing helper opened the Windows Print dialog and cancelled normally PASS'
  exit 0
 }
 if($helper.HasExited){throw 'Printing helper exited before its Windows Print dialog opened'}
 Start-Sleep -Milliseconds 250
}
throw 'Installed printing helper did not open the Windows Print dialog'
