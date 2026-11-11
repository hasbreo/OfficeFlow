#!/usr/bin/env bash
# Run from a VS 2026 developer environment in Git Bash, after building engine/.
set -euo pipefail
case "$(uname -s)" in MINGW*|MSYS*) ;; *) echo 'Native Windows toolchain required; refusing to generate a placeholder installer.' >&2; exit 2;; esac
if [ "$#" -ne 2 ]; then echo 'Usage: build-windows.sh CHECKOUT STAGING_DIRECTORY' >&2; exit 2; fi
project_dir=$(cd "$1" && pwd)
stage_dir=$2
script_dir=$(cd "$(dirname "$0")" && pwd)
for tool in python3 make msbuild cygpath; do command -v "$tool" >/dev/null || { echo "Missing $tool" >&2; exit 2; }; done
test -f "$project_dir/engine/instdir/program/setup.ini" || { echo 'Build the pinned CODAWindows engine first (see BUILD.md).' >&2; exit 2; }
python3 "$script_dir/prepare.py" "$project_dir"
cd "$project_dir"
./engine/solenv/bin/run-msys2 ./autogen.sh
./engine/solenv/bin/run-msys2 ./configure --enable-windowsapp --with-app-name=OfficeFlow --with-app-vendor=Hasbreo --with-lo-builddir="$project_dir/engine" --with-lo-path="$(cygpath -w "$project_dir/engine/instdir")" --with-info-url=https://hasbreo.com/officeflow/
./engine/solenv/bin/run-msys2 make -C browser
MSYS_NO_PATHCONV=1 msbuild /restore /p:Configuration=Release /p:Platform=x64 windows/coda/CODA.sln
payload="$project_dir/windows/coda/x64/Release/program"
test -s "$payload/OfficeFlow.exe" || { echo 'Native executable missing' >&2; exit 1; }
mkdir -p "$stage_dir"
cp -a "$payload/." "$stage_dir/"
for name in WordFlow CellFlow SlideFlow; do cp "$payload/OfficeFlow.exe" "$stage_dir/$name.exe"; done
echo 'Development native hosts staged. Do not publish: release gates in STATUS.md still apply.'
