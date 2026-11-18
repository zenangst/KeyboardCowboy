#!/bin/bash
set -uo pipefail

components_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
failed=0
manifests=()
for manifest in "$components_dir"/*/Package.swift; do
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
printf 'Checking %d components for tests\n' "$total"

for manifest in "${manifests[@]}"; do
  current=$((current + 1))
  package="${manifest%/Package.swift}"
  printf '%s==> [%d/%d] Testing %s%s\n' "$color" "$current" "$total" "${package##*/}" "$reset"
  if ! description="$(swift package --package-path "$package" describe)"; then
    failed=1
    continue
  fi
  if ! grep -q '^[[:space:]]*Type: test$' <<< "$description"; then
    echo "    Skipping: no test target"
    continue
  fi
  if ! swift test --package-path "$package" "$@"; then
    failed=1
  fi
done

exit "$failed"
