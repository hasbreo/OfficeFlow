param([Parameter(Mandatory=$true)][string]$Destination)
$ErrorActionPreference='Stop'
New-Item -ItemType Directory -Force (Split-Path $Destination) | Out-Null
Invoke-WebRequest 'https://go.microsoft.com/fwlink/p/?LinkId=2124703' -OutFile $Destination
$signature=Get-AuthenticodeSignature $Destination
if($signature.Status -ne 'Valid' -or $signature.SignerCertificate.Subject -notmatch 'Microsoft Corporation'){throw 'WebView2 bootstrapper signature verification failed'}
