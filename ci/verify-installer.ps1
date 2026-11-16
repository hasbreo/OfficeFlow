param([Parameter(Mandatory=$true)][string]$Installer)
$ErrorActionPreference='Stop'
$root=Join-Path $env:RUNNER_TEMP 'HasOffice install test ü'
$profile=Join-Path $env:APPDATA 'officeflow'
New-Item -ItemType Directory -Force "$profile/mail/test-account" | Out-Null
$sentinel=Join-Path $profile 'mail/test-account/retained.eml'
Set-Content -LiteralPath $sentinel -Value 'From: synthetic@example.invalid`nSubject: Retain this local test email' -Encoding utf8
$hash=(Get-FileHash $sentinel -Algorithm SHA256).Hash
Set-Content (Join-Path $profile 'settings.json') '{"autoUpdates":false,"theme":"dark"}' -Encoding utf8NoBOM
$old=Join-Path $env:RUNNER_TEMP 'OfficeFlow-Setup-0.5.1.exe'
Invoke-WebRequest 'https://hasbreo.com/downloads/officeflow/OfficeFlow-Setup-0.5.1.exe' -OutFile $old -UserAgent 'HasOffice-CI/0.5'
if((Get-FileHash $old -Algorithm SHA256).Hash.ToLowerInvariant() -ne 'bda7668a13be80654de2031bd77c445e693159900ec8fef2a56a36604ff1d1e1'){throw 'Prior installer checksum mismatch'}
function Install($file){
 $p=Start-Process -FilePath $file -ArgumentList "/S /D=$root" -PassThru
 if(-not $p.WaitForExit(240000)){$p.Kill();throw 'Silent installer did not finish within four minutes'}
 if($p.ExitCode -ne 0){throw "Installer exit code $($p.ExitCode)"}
}
Install $old
$runKey='HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
New-Item -Path $runKey -Force | Out-Null
New-ItemProperty -Path $runKey -Name MailFlow -Value ('"'+$root+'\MailFlow.exe" --background') -Force | Out-Null
Install (Resolve-Path $Installer)
$shell=New-Object -ComObject WScript.Shell
foreach($name in @('HasWord','HasCell','HasSlides','HasMail','HasPDF')){
 $native=$name -in @('HasWord','HasCell','HasSlides')
 $relative=if($native){"collabora/program/$name.exe"}else{"$name.exe"}
 $exe=Join-Path $root $relative
 if(-not(Test-Path $exe)){throw "Missing installed app $relative"}
 if((Get-Item $exe).VersionInfo.FileDescription -ne $name){throw "Wrong Windows identity for $name"}
 $shortcut=Join-Path ([Environment]::GetFolderPath('StartMenu')) "Programs/HasOffice/$name.lnk"
 if(-not(Test-Path $shortcut)){throw "Missing shortcut $name"}
 if($shell.CreateShortcut($shortcut).TargetPath -ne $exe){throw "Shortcut routes to wrong executable: $name"}
}
if((Get-ItemProperty $runKey).HasMail -notlike '*HasMail.exe*--background*'){throw 'Windows startup was not migrated'}
if((Get-ItemProperty $runKey -Name MailFlow -ErrorAction SilentlyContinue)){throw 'Legacy duplicate startup entry remains'}
if(Test-Path (Join-Path ([Environment]::GetFolderPath('StartMenu')) 'Programs/OfficeFlow')){throw 'Old Start menu group remains'}
foreach($oldName in @('WordFlow','CellFlow','SlideFlow','MailFlow','PDFFlow')){if(-not(Test-Path (Join-Path $root ($oldName+'.exe')))){throw 'Legacy shortcut target was removed'}}
if((Get-FileHash $sentinel -Algorithm SHA256).Hash -ne $hash){throw 'Upgrade changed local mail'}
"OFFICEFLOW_INSTALLED=$root" | Out-File $env:GITHUB_ENV -Append -Encoding utf8
"OFFICEFLOW_SENTINEL=$sentinel" | Out-File $env:GITHUB_ENV -Append -Encoding utf8
"OFFICEFLOW_SENTINEL_HASH=$hash" | Out-File $env:GITHUB_ENV -Append -Encoding utf8
Write-Host 'Upgrade, individual shortcut targets, Windows app identities and local-mail retention PASS'
