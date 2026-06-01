#!/usr/bin/env bash
set -euo pipefail

source scripts/ci/package-common.sh

version="$(odysseus_version)"
mkdir -p artifacts
git archive --format=tar.gz --prefix="odysseus-${version}/" -o "artifacts/odysseus-${version}.tar.gz" HEAD
sha256sum "artifacts/odysseus-${version}.tar.gz" > "artifacts/odysseus-${version}.tar.gz.sha256"
write_artifact_manifest artifacts
