$ErrorActionPreference = 'Stop'
$bin = 'C:\of-tools\bin'
$downloads = 'C:\of-tools\downloads'
New-Item -ItemType Directory -Force $bin,$downloads | Out-Null
function Fetch-Checked($Url, $Name, $Sha) {
  $file = Join-Path $downloads $Name
  Invoke-WebRequest -Uri $Url -OutFile $file
  if ((Get-FileHash $file -Algorithm SHA256).Hash.ToLowerInvariant() -ne $Sha) { throw "Checksum mismatch: $Name" }
  return $file
}
$make = Fetch-Checked 'https://gerrit.collaboraoffice.com/extern/make-4.4.1-msvc.exe' 'make.exe' '3cbf585a213001fbdedc5269621a3617d5067aba8f9dc8947054b76f30035e3d'
Copy-Item $make "$bin\make.exe"
$pkgconf = Fetch-Checked 'https://gerrit.collaboraoffice.com/extern/pkgconf-2.4.3.exe' 'pkgconf.exe' '791cd6dbc56f7268fbf9c4652d6634b0f5c59687ab4e504565e58245952edd41'
Copy-Item $pkgconf "$bin\pkgconf.exe"
Copy-Item $pkgconf "$bin\pkgconf-2.4.3.exe"
$jom = Fetch-Checked 'https://download.qt.io/official_releases/jom/jom_1_1_4.zip' 'jom.zip' 'd533c1ef49214229681e90196ed2094691e8c4a0a0bef0b2c901debcb562682b'
Expand-Archive $jom "$downloads\jom" -Force
Copy-Item "$downloads\jom\jom.exe" "$bin\jom.exe"
$perl = Fetch-Checked 'https://github.com/StrawberryPerl/Perl-Dist-Strawberry/releases/download/SP_54001_64bit_UCRT/strawberry-perl-5.40.0.1-64bit-portable.zip' 'perl.zip' '754f3e2a8e473dc68d1540c7802fb166a025f35ef18960c4564a31f8b5933907'
Expand-Archive $perl 'C:\of-tools\spp' -Force
$env:Path = "C:\of-tools\spp\c\bin;C:\of-tools\spp\perl\bin;$env:Path"
$env:PERL_MM_USE_DEFAULT = '1'
& 'C:\of-tools\spp\perl\bin\cpanm.bat' --notest Font::TTF
if ($LASTEXITCODE -ne 0) { throw 'Perl Font::TTF dependency installation failed' }
$bin | Out-File -FilePath $env:GITHUB_PATH -Append -Encoding utf8
'C:\of-tools\spp\perl\bin' | Out-File -FilePath $env:GITHUB_PATH -Append -Encoding utf8
# Only the disposable CI machine is affected; native source tarballs need symlinks.
New-Item -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock' -Force | Out-Null
New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock' -Name AllowDevelopmentWithoutDevLicense -PropertyType DWord -Value 1 -Force | Out-Null
'MSYS=winsymlinks:nativestrict' | Out-File -FilePath $env:GITHUB_ENV -Append -Encoding utf8
