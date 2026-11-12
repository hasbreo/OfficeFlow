param([Parameter(Mandatory=$true)][int]$ProcessId,[Parameter(Mandatory=$true)][string]$Destination)
$ErrorActionPreference='Stop'
Add-Type -AssemblyName UIAutomationClient,UIAutomationTypes
$condition=New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::ProcessIdProperty,$ProcessId)
$editCondition=New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::ControlTypeProperty,[System.Windows.Automation.ControlType]::Edit)
$saveCondition=New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::NameProperty,'Save')
$deadline=(Get-Date).AddSeconds(45)
while((Get-Date) -lt $deadline){
 $windows=[System.Windows.Automation.AutomationElement]::RootElement.FindAll([System.Windows.Automation.TreeScope]::Children,$condition)
 foreach($window in $windows){
  $edits=$window.FindAll([System.Windows.Automation.TreeScope]::Descendants,$editCondition)
  $written=$false
  foreach($edit in $edits){
   if($edit.Current.AutomationId -ne '1001' -and $edit.Current.Name -notlike '*File name*'){continue}
   $pattern=$null
   if($edit.TryGetCurrentPattern([System.Windows.Automation.ValuePattern]::Pattern,[ref]$pattern) -and -not $pattern.Current.IsReadOnly){
    $pattern.SetValue($Destination);$written=$true;break
   }
  }
  if(-not $written){continue}
  $save=$window.FindFirst([System.Windows.Automation.TreeScope]::Descendants,$saveCondition)
  if($null -eq $save){continue}
  $save.GetCurrentPattern([System.Windows.Automation.InvokePattern]::Pattern).Invoke()
  Write-Host 'Native PDF save dialog accepted';exit 0
 }
 Start-Sleep -Milliseconds 250
}
foreach($window in $windows){
 Write-Host ('Window: '+$window.Current.Name)
 foreach($edit in $window.FindAll([System.Windows.Automation.TreeScope]::Descendants,$editCondition)){
  Write-Host ('Edit: '+$edit.Current.AutomationId+' / '+$edit.Current.Name)
 }
}
throw 'Native PDF save dialog was not found'
