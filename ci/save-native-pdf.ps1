param([Parameter(Mandatory=$true)][int]$ProcessId,[Parameter(Mandatory=$true)][string]$Destination)
$ErrorActionPreference='Stop'
Add-Type -AssemblyName UIAutomationClient,UIAutomationTypes,System.Windows.Forms,System.Drawing
Add-Type @'
using System;
using System.Collections.Generic;
using System.Text;
using System.Runtime.InteropServices;
public static class OfficeFlowSaveTest {
 public delegate bool EnumProc(IntPtr window,IntPtr data);
 [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc callback,IntPtr data);
 [DllImport("user32.dll",CharSet=CharSet.Unicode)] public static extern int GetClassName(IntPtr window,StringBuilder value,int capacity);
 [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr window);
 [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr window);
 [DllImport("user32.dll")] public static extern IntPtr GetWindow(IntPtr window,uint command);
 [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr window,out uint process);
 public static bool OwnedBy(IntPtr window,int process) {
  for(int i=0;i<10 && window!=IntPtr.Zero;i++) {
   uint owner;GetWindowThreadProcessId(window,out owner);
   if(owner==process)return true;
   window=GetWindow(window,4);
  }
  return false;
 }
 public static IntPtr[] Dialogs(int process) {
  var result=new List<IntPtr>();
  EnumWindows((window,data)=>{
   var name=new StringBuilder(256);GetClassName(window,name,name.Capacity);
   if(name.ToString()=="#32770" && IsWindowVisible(window) && OwnedBy(window,process))result.Add(window);
   return true;
  },IntPtr.Zero);
  return result.ToArray();
 }
}
'@
function CaptureFailure {
 $all=[System.Windows.Automation.AutomationElement]::RootElement.FindAll([System.Windows.Automation.TreeScope]::Children,[System.Windows.Automation.Condition]::TrueCondition)
 foreach($item in $all){Write-Host "Desktop window: $($item.Current.ProcessId) / $($item.Current.ClassName) / $($item.Current.Name)"}
 $bounds=[System.Windows.Forms.Screen]::PrimaryScreen.Bounds
 $bitmap=New-Object System.Drawing.Bitmap($bounds.Width,$bounds.Height)
 $graphics=[System.Drawing.Graphics]::FromImage($bitmap)
 try {
  $graphics.CopyFromScreen($bounds.Location,[System.Drawing.Point]::Empty,$bounds.Size)
  $bitmap.Save([System.IO.Path]::ChangeExtension($Destination,'.dialog.png'),[System.Drawing.Imaging.ImageFormat]::Png)
 } finally {$graphics.Dispose();$bitmap.Dispose()}
}
$deadline=(Get-Date).AddSeconds(45)
while((Get-Date) -lt $deadline){
 foreach($handle in [OfficeFlowSaveTest]::Dialogs($ProcessId)){
  # UIA can nest a native owned dialog below the application window. Resolve
  # its Win32 handle directly instead of assuming it is a desktop child.
  $window=[System.Windows.Automation.AutomationElement]::FromHandle($handle)
  $fileNameCondition=New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::AutomationIdProperty,'FileNameControlHost')
  $fileName=$window.FindFirst([System.Windows.Automation.TreeScope]::Descendants,$fileNameCondition)
  if($window.Current.Name -notin @('Save As','Save') -and -not ($window.Current.ClassName -eq '#32770' -and $fileName)){continue}
  [void][OfficeFlowSaveTest]::SetForegroundWindow([IntPtr]$window.Current.NativeWindowHandle)
  [System.Windows.Forms.Clipboard]::SetText($Destination)
  [System.Windows.Forms.SendKeys]::SendWait('%n')
  [System.Windows.Forms.SendKeys]::SendWait('^a')
  [System.Windows.Forms.SendKeys]::SendWait('^v')
  [System.Windows.Forms.SendKeys]::SendWait('{ENTER}')
  $saved=(Get-Date).AddSeconds(15)
  while((Get-Date) -lt $saved){if(Test-Path -LiteralPath $Destination){Write-Host 'Native PDF save dialog accepted';exit 0};Start-Sleep -Milliseconds 200}
  CaptureFailure
  throw 'Save dialog did not write the requested PDF'
 }
 Start-Sleep -Milliseconds 250
}
CaptureFailure
throw 'Native PDF save dialog was not found'
