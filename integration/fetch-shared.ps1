$ErrorActionPreference='Stop'
$lock=Get-Content "$PSScriptRoot/source.lock.json" -Raw | ConvertFrom-Json
$zip=Join-Path $env:RUNNER_TEMP 'officeflow-shared.zip'
Invoke-WebRequest $lock.url -OutFile $zip -UserAgent 'OfficeFlow-CI/0.5'
if((Get-FileHash $zip -Algorithm SHA256).Hash.ToLowerInvariant() -ne $lock.sha256){throw 'Shared source checksum mismatch'}
$dest=Join-Path $env:RUNNER_TEMP 'officeflow-shared'
Expand-Archive $zip $dest -Force
"OFFICEFLOW_SHARED=$dest/OfficeFlow" | Out-File $env:GITHUB_ENV -Append -Encoding utf8
