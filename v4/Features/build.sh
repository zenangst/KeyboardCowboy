#!/bin/bash
set -uo pipefail

features_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
failed=0
manifests=()
for manifest in "$features_dir"/*/Package.swift; do
  [[ -f "$manifest" ]] && manifests+=("$manifest")
done

total="${#manifests[@]}"
current=0
color=""
reset=""
if [[ -t 1 && -z "${NO_COLOR:-}" && "${TERM:-}" != "dumb" ]]; then
  color=$'\033[1;36m'
  reset=$'\033[0m'
fi
printf 'Building %d features\n' "$total"

for manifest in "${manifests[@]}"; do
  current=$((current + 1))
  package="${manifest%/Package.swift}"
  printf '%s==> [%d/%d] Building %s%s\n' "$color" "$current" "$total" "${package##*/}" "$reset"
  if ! swift build --package-path "$package" "$@"; then
    failed=1
  fi
done

exit "$failed"
