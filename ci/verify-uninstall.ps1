$ErrorActionPreference='Stop'
$root=$env:OFFICEFLOW_INSTALLED
Start-Process -FilePath (Join-Path $root 'Uninstall OfficeFlow.exe') -ArgumentList '/S' -Wait
$deadline=(Get-Date).AddSeconds(60)
while((Test-Path (Join-Path $root 'MailFlow.exe')) -and (Get-Date) -lt $deadline){Start-Sleep -Milliseconds 250}
if(Test-Path (Join-Path $root 'MailFlow.exe')){throw 'Uninstall did not remove app binaries'}
if((Get-FileHash $env:OFFICEFLOW_SENTINEL -Algorithm SHA256).Hash -ne $env:OFFICEFLOW_SENTINEL_HASH){throw 'Uninstall changed local mail'}
$old=Join-Path $env:RUNNER_TEMP 'OfficeFlow-Setup-0.4.3.exe'
$p=Start-Process -FilePath $old -ArgumentList "/S /D=$root" -Wait -PassThru
if($p.ExitCode -ne 0){throw 'Rollback installation failed'}
if((Get-Item (Join-Path $root 'MailFlow.exe')).VersionInfo.ProductVersion -notlike '0.4.3*'){throw 'Rollback restored the wrong version'}
if((Get-FileHash $env:OFFICEFLOW_SENTINEL -Algorithm SHA256).Hash -ne $env:OFFICEFLOW_SENTINEL_HASH){throw 'Rollback changed local mail'}
Write-Host 'Uninstall and rollback preserve local mail PASS'
