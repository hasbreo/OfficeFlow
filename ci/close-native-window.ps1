param([Parameter(Mandatory=$true)][int]$ProcessId)
$ErrorActionPreference='Stop'
Add-Type @'
using System;
using System.Text;
using System.Collections.Generic;
using System.Runtime.InteropServices;
public static class OfficeFlowTestWindow {
 public delegate bool EnumProc(IntPtr window,IntPtr data);
 [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc callback,IntPtr data);
 [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr window,out uint process);
 [DllImport("user32.dll",CharSet=CharSet.Unicode)] public static extern int GetClassName(IntPtr window,StringBuilder value,int capacity);
 [DllImport("user32.dll",CharSet=CharSet.Unicode)] public static extern int GetWindowText(IntPtr window,StringBuilder value,int capacity);
 [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr window);
 [DllImport("user32.dll")] public static extern bool PostMessage(IntPtr window,uint message,IntPtr wp,IntPtr lp);
 public static IntPtr[] EditorWindows(int process) {
  var result=new List<IntPtr>();
  EnumWindows((window,data)=>{
   uint owner;GetWindowThreadProcessId(window,out owner);
   if(owner==process){
    var name=new StringBuilder(256);GetClassName(window,name,name.Capacity);
    var title=new StringBuilder(512);GetWindowText(window,title,title.Capacity);
    Console.WriteLine("Owned window: "+name+" / "+title);
    if(name.ToString()=="CODA" && IsWindowVisible(window))result.Add(window);
   }
   return true;
  },IntPtr.Zero);
  return result.ToArray();
 }
}
'@
$windows=[OfficeFlowTestWindow]::EditorWindows($ProcessId)
if(-not $windows.Count){throw 'Native editor has no visible CODA window'}
foreach($window in $windows){if(-not [OfficeFlowTestWindow]::PostMessage($window,0x10,[IntPtr]::Zero,[IntPtr]::Zero)){throw 'Close request failed'}}
