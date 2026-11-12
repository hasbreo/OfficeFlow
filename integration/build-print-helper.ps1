param([Parameter(Mandatory=$true)][string]$Destination)
$ErrorActionPreference='Stop'
$lock=Get-Content "$PSScriptRoot/../collabora/upstream.lock.json" -Raw | ConvertFrom-Json
$source=Join-Path $env:RUNNER_TEMP 'officeflow-print-source'
New-Item -ItemType Directory -Force $source | Out-Null
foreach($name in @('PrintPDFAndDelete.cs','PrintPDFAndDelete.csproj')){
 $url="https://raw.githubusercontent.com/CollaboraOnline/online.mirror/$($lock.commit)/windows/coda/PrintPDFAndDelete/$name"
 Invoke-WebRequest $url -OutFile (Join-Path $source $name)
}
# Include the desktop runtime so printing works on a PC without a .NET install.
dotnet publish (Join-Path $source 'PrintPDFAndDelete.csproj') -c Release -r win-x64 --self-contained true -p:PublishSingleFile=false -o $Destination
if($LASTEXITCODE -ne 0){throw 'Self-contained printing helper build failed'}
if(-not(Test-Path (Join-Path $Destination 'coreclr.dll'))){throw 'Printing runtime was not bundled'}
