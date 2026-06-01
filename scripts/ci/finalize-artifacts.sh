#!/usr/bin/env bash
set -euo pipefail

artifact_dir="${1:-artifacts}"
artifact_name="${2:-unknown}"
artifact_version="${3:-0.0.0}"
artifact_platform="${4:-linux}"
artifact_type="${5:-unknown}"

mkdir -p "$artifact_dir"

python3 - "$artifact_dir" "$artifact_name" "$artifact_version" "$artifact_platform" "$artifact_type" "${GITHUB_SHA:-unknown}" "${GITHUB_RUN_ID:-local}" "${GITHUB_REPOSITORY:-unknown}" <<'PY'
from pathlib import Path
import hashlib
import json
import sys
import os
from datetime import datetime, timezone

artifact_dir   = Path(sys.argv[1])
artifact_name  = sys.argv[2]
version        = sys.argv[3]
platform       = sys.argv[4]
artifact_type  = sys.argv[5]
commit_sha     = sys.argv[6]
run_id         = sys.argv[7]
repository     = sys.argv[8]

artifact_dir.mkdir(parents=True, exist_ok=True)

excluded = {"manifest.txt", "SHA256SUMS", "metadata.json"}
payload_files = sorted(
    p for p in artifact_dir.iterdir()
    if p.is_file() and p.name not in excluded
)

# SHA256SUMS
sha_path = artifact_dir / "SHA256SUMS"
digests = {}
with sha_path.open("w", encoding="utf-8") as out:
    for path in payload_files:
        digest = hashlib.sha256(path.read_bytes()).hexdigest()
        out.write(f"{digest}  {path.name}\n")
        digests[path.name] = {"sha256": digest, "size_bytes": path.stat().st_size}

# manifest.txt
all_files = sorted(p.name for p in artifact_dir.iterdir() if p.is_file())
manifest_path = artifact_dir / "manifest.txt"
with manifest_path.open("a", encoding="utf-8") as out:
    out.write(f"artifact_count={len(payload_files)}\n")
    out.write("artifact_files<<EOF\n")
    for name in all_files:
        out.write(f"{name}\n")
    out.write("EOF\n")

# metadata.json — machine-readable artifact metadata
build_url = ""
if run_id != "local" and repository != "unknown":
    build_url = f"https://github.com/{repository}/actions/runs/{run_id}"

metadata = {
    "schema_version": "1.0",
    "artifact": {
        "name": artifact_name,
        "version": version,
        "type": artifact_type,
        "platform": platform,
    },
    "build": {
        "commit": commit_sha,
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "run_id": run_id,
        "url": build_url,
        "ci": bool(os.getenv("CI", "")),
    },
    "files": [
        {
            "name": f["name"],
            **digests.get(f["name"], {}),
        }
        for f in sorted(
            ({"name": p.name, "size": p.stat().st_size} for p in payload_files),
            key=lambda x: x["name"],
        )
    ],
}

meta_path = artifact_dir / "metadata.json"
with meta_path.open("w", encoding="utf-8") as out:
    json.dump(metadata, out, indent=2, ensure_ascii=False)
    out.write("\n")
PY
