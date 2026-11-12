$ErrorActionPreference='Stop'
$complete=Test-Path 'C:/of-build/.officeflow-engine-complete'
if(-not $complete){
 # The runner stops the compiler tree at the step's time limit. Discard recent
 # intermediate files so no interrupted object or library can be reused.
 $recent=(Get-Date).ToUniversalTime().AddMinutes(-2)
 foreach($root in @('C:/of-build/engine/workdir','C:/of-build/engine/instdir')){
  if(Test-Path $root){Get-ChildItem $root -Recurse -File | Where-Object LastWriteTimeUtc -gt $recent | Remove-Item -Force}
 }
}
"complete=$($complete.ToString().ToLowerInvariant())" | Out-File $env:GITHUB_OUTPUT -Append -Encoding utf8
$code=if(Test-Path 'C:/of-build/officeflow-engine-result'){[int](Get-Content 'C:/of-build/officeflow-engine-result')}else{-1}
"result=$code" | Out-File $env:GITHUB_OUTPUT -Append -Encoding utf8
Write-Host "Engine completion: $complete; build result: $code"
