#!/usr/bin/env bash
set -euo pipefail

artifact_dir="${1:-artifacts}"
mkdir -p "$artifact_dir"

if find "$artifact_dir" -maxdepth 1 -type f ! -name 'manifest.txt' ! -name 'SHA256SUMS' | grep -q .; then
  (
    cd "$artifact_dir"
    find . -maxdepth 1 -type f ! -name 'manifest.txt' ! -name 'SHA256SUMS' -printf '%P\n' \
      | sort \
      | xargs -r sha256sum > SHA256SUMS
  )
else
  : > "$artifact_dir/SHA256SUMS"
fi

{
  echo "artifact_count=$(find "$artifact_dir" -maxdepth 1 -type f ! -name 'manifest.txt' ! -name 'SHA256SUMS' | wc -l | tr -d ' ')"
  echo "artifact_files<<EOF"
  find "$artifact_dir" -maxdepth 1 -type f -printf '%f\n' | sort
  echo "EOF"
} >> "$artifact_dir/manifest.txt"
