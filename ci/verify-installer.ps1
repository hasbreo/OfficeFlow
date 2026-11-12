param([Parameter(Mandatory=$true)][string]$Installer)
$ErrorActionPreference='Stop'
$root=Join-Path $env:RUNNER_TEMP 'OfficeFlow install test ü'
$profile=Join-Path $env:APPDATA 'officeflow'
New-Item -ItemType Directory -Force "$profile/mail/test-account" | Out-Null
$sentinel=Join-Path $profile 'mail/test-account/retained.eml'
Set-Content -LiteralPath $sentinel -Value 'From: synthetic@example.invalid`nSubject: Retain this local test email' -Encoding utf8
$hash=(Get-FileHash $sentinel -Algorithm SHA256).Hash
Set-Content (Join-Path $profile 'settings.json') '{"autoUpdates":false,"theme":"dark"}' -Encoding utf8NoBOM
$old=Join-Path $env:RUNNER_TEMP 'OfficeFlow-Setup-0.4.3.exe'
Invoke-WebRequest 'https://hasbreo.com/downloads/officeflow/OfficeFlow-Setup-0.4.3.exe' -OutFile $old -UserAgent 'OfficeFlow-CI/0.5'
if((Get-FileHash $old -Algorithm SHA256).Hash.ToLowerInvariant() -ne 'a93b76d6d02ed8f3025071317905dd2cec73d2e40097259022fc130fc3f13f2a'){throw 'Prior installer checksum mismatch'}
function Install($file){
 $p=Start-Process -FilePath $file -ArgumentList "/S /D=$root" -Wait -PassThru
 if($p.ExitCode -ne 0){throw "Installer exit code $($p.ExitCode)"}
}
Install $old
Install (Resolve-Path $Installer)
$shell=New-Object -ComObject WScript.Shell
foreach($name in @('WordFlow','CellFlow','SlideFlow','MailFlow','PDFFlow')){
 $native=$name -in @('WordFlow','CellFlow','SlideFlow')
 $relative=if($native){"collabora/program/$name.exe"}else{"$name.exe"}
 $exe=Join-Path $root $relative
 if(-not(Test-Path $exe)){throw "Missing installed app $relative"}
 if((Get-Item $exe).VersionInfo.FileDescription -ne $name){throw "Wrong Windows identity for $name"}
 $shortcut=Join-Path ([Environment]::GetFolderPath('StartMenu')) "Programs/OfficeFlow/$name.lnk"
 if(-not(Test-Path $shortcut)){throw "Missing shortcut $name"}
 if($shell.CreateShortcut($shortcut).TargetPath -ne $exe){throw "Shortcut routes to wrong executable: $name"}
}
if((Get-FileHash $sentinel -Algorithm SHA256).Hash -ne $hash){throw 'Upgrade changed local mail'}
"OFFICEFLOW_INSTALLED=$root" | Out-File $env:GITHUB_ENV -Append -Encoding utf8
"OFFICEFLOW_SENTINEL=$sentinel" | Out-File $env:GITHUB_ENV -Append -Encoding utf8
"OFFICEFLOW_SENTINEL_HASH=$hash" | Out-File $env:GITHUB_ENV -Append -Encoding utf8
Write-Host 'Upgrade, individual shortcut targets, Windows app identities and local-mail retention PASS'
