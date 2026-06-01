#!/usr/bin/env bash
set -euo pipefail

python -m pip install --upgrade pip build
rm -rf build dist *.egg-info
python -m build --sdist --wheel
python -m pip check

mkdir -p artifacts
cp dist/* artifacts/
source scripts/ci/package-common.sh
write_artifact_manifest artifacts
