param([Parameter(Mandatory=$true)][int]$ProcessId,[Parameter(Mandatory=$true)][string]$Destination)
$ErrorActionPreference='Stop'
Add-Type -AssemblyName UIAutomationClient,UIAutomationTypes
$condition=New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::ProcessIdProperty,$ProcessId)
$nameCondition=New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::NameProperty,'File name:')
$saveCondition=New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::NameProperty,'Save')
$deadline=(Get-Date).AddSeconds(45)
while((Get-Date) -lt $deadline){
 $windows=[System.Windows.Automation.AutomationElement]::RootElement.FindAll([System.Windows.Automation.TreeScope]::Children,$condition)
 foreach($window in $windows){
  $edit=$window.FindFirst([System.Windows.Automation.TreeScope]::Descendants,$nameCondition)
  if($null -eq $edit){continue}
  $pattern=$edit.GetCurrentPattern([System.Windows.Automation.ValuePattern]::Pattern)
  $pattern.SetValue($Destination)
  $save=$window.FindFirst([System.Windows.Automation.TreeScope]::Descendants,$saveCondition)
  if($null -eq $save){continue}
  $save.GetCurrentPattern([System.Windows.Automation.InvokePattern]::Pattern).Invoke()
  Write-Host 'Native PDF save dialog accepted';exit 0
 }
 Start-Sleep -Milliseconds 250
}
throw 'Native PDF save dialog was not found'
