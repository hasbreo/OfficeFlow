#!/usr/bin/env bash
# A resumable source build for a hosted runner with a finite job duration.
set -euo pipefail
repo=$(pwd)
export TMPDIR=C:/of-temp TMP=C:/of-temp TEMP=C:/of-temp
mkdir -p /c/of-temp /c/tmp /c/of-build
rm -f /c/of-build/officeflow-engine-result
commit=$(python -c 'import json;print(json.load(open("collabora/upstream.lock.json"))["commit"])')
if [[ -s /c/of-build/.officeflow-engine-complete ]]; then
  # A completed SDK cache may not include the source checkout. The normal bootstrap
  # recreates that checkout and validates the pinned completion marker.
  test "$(cat /c/of-build/.officeflow-engine-complete)" = "$commit"
  if [[ -d /c/of-source/.git ]]; then
    test "$(git -C /c/of-source rev-parse HEAD)" = "$commit"
  else
    bash collabora/ci-build.sh engine
  fi
  code=0
elif [[ -d /c/of-source/.git && -f /c/of-build/coda-config.mk && -f /c/of-build/engine/config_host.mk ]]; then
  test "$(git -C /c/of-source rev-parse HEAD)" = "$commit"
  # Keep source and generated-header timestamps intact so completed objects remain valid.
  cd /c/of-build
  set +e
  make engine 2>&1 | tee engine-resume.log
  code=${PIPESTATUS[0]}
  set -e
  if [[ "$code" == 0 ]]; then printf '%s\n' "$commit" > .officeflow-engine-complete; fi
else
  set +e
  bash collabora/ci-build.sh engine
  code=$?
  set -e
fi
printf '%s\n' "$code" > /c/of-build/officeflow-engine-result
exit "$code"
