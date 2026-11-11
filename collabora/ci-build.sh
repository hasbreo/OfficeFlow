#!/usr/bin/env bash
set -euo pipefail
repo=$(pwd)
source_dir=/c/of-source
build_dir=/c/of-build
commit=$(python -c 'import json; print(json.load(open("collabora/upstream.lock.json"))["commit"])')
git -c core.autocrlf=false init "$source_dir"
git -C "$source_dir" remote add origin https://github.com/CollaboraOnline/online.mirror.git
git -C "$source_dir" config core.symlinks true
git -C "$source_dir" config core.autocrlf false
git -C "$source_dir" -c core.autocrlf=false fetch --depth=1 origin "$commit"
git -C "$source_dir" -c core.autocrlf=false checkout --detach FETCH_HEAD
python "$repo/collabora/prepare.py" "$source_dir"
mkdir -p "$build_dir" /c/of-downloads
cat > "$build_dir/autogen.input" <<'EOF'
--with-distro=CODAWindows
--host=x86_64-pc-cygwin
--with-visual-studio=2026
--with-strawberry-perl-portable=C:\of-tools\spp
--with-external-tar=C:\of-downloads
--with-lang=en-US
--with-parallelism=2
--without-junit
PKG_CONFIG=/c/of-tools/bin/pkgconf-2.4.3.exe
EOF
cd "$build_dir"
"$source_dir/windows/coda/build/autogen.sh" 2>&1 | tee configure.log
make CONFIG=Release APP_NAME=OfficeFlow VENDOR=Hasbreo INFO_URL=https://hasbreo.com/officeflow/ 2>&1 | tee build.log
native="$build_dir/online/windows/coda/x64/Release/program"
test -s "$native/OfficeFlow.exe"
for app in WordFlow CellFlow SlideFlow; do cp "$native/OfficeFlow.exe" "$native/$app.exe"; done
echo 'Native development build completed. Installer and release validation are separate gates.'
