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
 [DllImport("user32.dll")] public static extern bool PostMessage(IntPtr window,uint message,IntPtr wParam,IntPtr lParam);
 [DllImport("kernel32.dll",SetLastError=true)] public static extern IntPtr OpenProcess(uint access,bool inherit,int process);
 [DllImport("kernel32.dll")] public static extern uint WaitForSingleObject(IntPtr handle,uint milliseconds);
 [DllImport("kernel32.dll")] public static extern bool GetExitCodeProcess(IntPtr handle,out uint code);
 [DllImport("kernel32.dll")] public static extern bool CloseHandle(IntPtr handle);
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
# Retain an OS process handle before cancelling; Get-Process can lose ExitCode
# when the externally launched process exits before its handle is cached.
$helperHandle=[OfficeFlowPrintTestWindow]::OpenProcess(0x00101000,$false,$helper.Id)
if($helperHandle -eq [IntPtr]::Zero){throw 'Could not retain the printing helper process handle'}
while((Get-Date) -lt $deadline){
 foreach($handle in [OfficeFlowPrintTestWindow]::Dialogs($helper.Id)){
  $window=[System.Windows.Automation.AutomationElement]::FromHandle($handle)
  if($window.Current.Name -ne 'Print'){continue}
  $cancelCondition=New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::NameProperty,'Cancel')
  $cancel=$window.FindFirst([System.Windows.Automation.TreeScope]::Descendants,$cancelCondition)
  if(-not $cancel){throw 'Windows Print dialog has no Cancel button'}
  # The common print dialog exposes its Cancel label without InvokePattern.
  # IDCANCEL is the standard dialog command and follows the same cancel path.
  if(-not [OfficeFlowPrintTestWindow]::PostMessage($handle,0x0111,[IntPtr]2,[IntPtr]::Zero)){throw 'Could not send the print dialog Cancel command'}
  if([OfficeFlowPrintTestWindow]::WaitForSingleObject($helperHandle,15000) -ne 0){throw 'Printing helper did not exit after Cancel'}
  [uint32]$result=0
  if(-not [OfficeFlowPrintTestWindow]::GetExitCodeProcess($helperHandle,[ref]$result)){throw 'Could not read printing helper exit code'}
  [void][OfficeFlowPrintTestWindow]::CloseHandle($helperHandle)
  if($result -ne 0){throw "Printing helper failed: $result"}
  Write-Host 'Installed native printing helper opened the Windows Print dialog and cancelled normally PASS'
  exit 0
 }
 if($helper.HasExited){throw 'Printing helper exited before its Windows Print dialog opened'}
 Start-Sleep -Milliseconds 250
}
throw 'Installed printing helper did not open the Windows Print dialog'
