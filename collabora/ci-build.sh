#!/usr/bin/env bash
set -euo pipefail
repo=$(pwd)
source_dir=/c/of-source
build_dir=/c/of-build
mkdir -p /c/of-temp /c/tmp
# Native make cannot interpret MSYS2's default /tmp as a Windows filesystem path.
export TMPDIR=C:/of-temp TMP=C:/of-temp TEMP=C:/of-temp
# Some native make builds fall back to /tmp (a drive-root path on Windows).
# Keep that fallback on this disposable runner and verify stdin makefiles early.
printf 'all:;@echo native-make-stdin-ok\n' | /c/of-tools/bin/make.exe -f -
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
--with-parallelism=4
--without-junit
PKG_CONFIG=/c/of-tools/bin/pkgconf-2.4.3.exe
MAKE=/c/of-tools/bin/make.exe
GNUMAKE=/c/of-tools/bin/make.exe
JOM=/c/of-tools/bin/jom.exe
--disable-symbols
EOF
cd "$build_dir"
"$source_dir/windows/coda/build/autogen.sh" 2>&1 | tee configure.log
make CONFIG=Release APP_NAME=OfficeFlow VENDOR=Hasbreo INFO_URL=https://hasbreo.com/officeflow/ ONLINE_CONFIGURE_ARGS="--with-app-branding=$repo/collabora/branding" 2>&1 | tee build.log
native="$build_dir/online/windows/coda/x64/Release/program"
test -s "$native/OfficeFlow.exe"
for app in WordFlow CellFlow SlideFlow; do cp "$native/OfficeFlow.exe" "$native/$app.exe"; done
mkdir -p "$native/../templates"
cp "$repo/collabora/templates/"* "$native/../templates/"
echo 'Native development build completed. Installer and release validation are separate gates.'
