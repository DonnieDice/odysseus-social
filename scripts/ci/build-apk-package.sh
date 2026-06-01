#!/usr/bin/env bash
set -euo pipefail

source scripts/ci/package-common.sh

target="${1:?usage: build-apk-package.sh <target-suffix>}"
version="$(odysseus_version)"
staging="/tmp/odysseus-apk-${target}"

stage_odysseus_tree "$staging"
mkdir -p "$staging/etc/init.d"
cat > "$staging/etc/init.d/odysseus" <<'EOF'
#!/sbin/openrc-run
name="odysseus"
description="Odysseus AI Workspace"
command="/opt/odysseus/.venv/bin/python"
command_args="-m uvicorn app:app --host 0.0.0.0 --port 7000"
command_user="odysseus:odysseus"
directory="/opt/odysseus"
pidfile="/run/odysseus.pid"
command_background="yes"
depend() {
  need net
}
EOF
chmod 755 "$staging/etc/init.d/odysseus"

mkdir -p artifacts
tar -C "$staging" -czf "artifacts/odysseus-ai-workspace_${version}_${target}_amd64.apk.tar.gz" .
write_artifact_manifest artifacts
