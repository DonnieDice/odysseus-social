#!/usr/bin/env bash
set -euo pipefail

source scripts/ci/package-common.sh

target="${1:?usage: build-deb-package.sh <target-suffix>}"
version="$(odysseus_version)"
staging="/tmp/odysseus-deb-${target}"
package_root="${staging}/pkg"

stage_odysseus_tree "$package_root"
mkdir -p "$package_root/DEBIAN"
cat > "$package_root/DEBIAN/control" <<EOF
Package: odysseus-ai-workspace
Version: ${version}
Section: net
Priority: optional
Architecture: amd64
Maintainer: Odysseus Maintainers <maintainers@example.invalid>
Depends: python3 (>= 3.11), python3-venv, python3-pip, systemd
Description: Self-hosted AI workspace
 Odysseus provides a self-hosted AI workspace with chat, agents, research,
 documents, memory, email, calendar, and local tools.
EOF
cat > "$package_root/DEBIAN/postinst" <<'EOF'
#!/bin/sh
set -e
if ! getent group odysseus >/dev/null; then
  addgroup --system odysseus
fi
if ! getent passwd odysseus >/dev/null; then
  adduser --system --ingroup odysseus --home /var/lib/odysseus --no-create-home odysseus
fi
chown -R odysseus:odysseus /var/lib/odysseus /var/log/odysseus
python3 -m venv /opt/odysseus/.venv
/opt/odysseus/.venv/bin/python -m pip install --upgrade pip
/opt/odysseus/.venv/bin/python -m pip install -r /opt/odysseus/requirements.txt
systemctl daemon-reload || true
EOF
chmod 755 "$package_root/DEBIAN/postinst"

mkdir -p artifacts
dpkg-deb --build "$package_root" "artifacts/odysseus-ai-workspace_${version}_${target}_amd64.deb"
write_artifact_manifest artifacts
