#!/usr/bin/env bash
set -euo pipefail

git config --global --add safe.directory "${PWD}" >/dev/null 2>&1 || true

odysseus_version() {
  python3 - <<'PY'
import tomllib
with open("pyproject.toml", "rb") as fh:
    print(tomllib.load(fh)["project"]["version"])
PY
}

stage_odysseus_tree() {
  local root="$1"
  rm -rf "$root"
  mkdir -p "$root/opt/odysseus" "$root/etc/odysseus" "$root/usr/lib/systemd/system" \
    "$root/var/lib/odysseus" "$root/var/log/odysseus"

  git archive --format=tar HEAD | tar -C "$root/opt/odysseus" -xf -
  install -Dm644 packaging/systemd/odysseus.service "$root/usr/lib/systemd/system/odysseus.service"
  install -Dm644 packaging/odysseus.env.example "$root/etc/odysseus/odysseus.env"
}

write_artifact_manifest() {
  local artifact_dir="${1:-artifacts}"
  mkdir -p "$artifact_dir"
  {
    echo "commit=$(git rev-parse HEAD)"
    echo "version=$(odysseus_version)"
    echo "built_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  } > "$artifact_dir/manifest.txt"
}
