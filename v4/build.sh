#!/bin/bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
components_color=""
features_color=""
reset=""
if [[ -t 1 && -z "${NO_COLOR:-}" && "${TERM:-}" != "dumb" ]]; then
  components_color=$'\033[1;35m'
  features_color=$'\033[1;32m'
  reset=$'\033[0m'
fi

printf '\n%s=== Building Components ===%s\n' "$components_color" "$reset"
"$root_dir/Components/build.sh" "$@"
printf '\n%s=== Building Features ===%s\n' "$features_color" "$reset"
"$root_dir/Features/build.sh" "$@"
for manifest in "$root_dir"/Triggers/*/Package.swift; do
  [[ -f "$manifest" ]] || continue
  package_dir="${manifest%/Package.swift}"
  printf '\n=== Building Trigger: %s ===\n' "${package_dir##*/}"
  swift build --package-path "$package_dir" "$@"
done
for package in Editor Service; do
  printf '\n=== Building %s ===\n' "$package"
  swift build --package-path "$root_dir/$package" "$@"
done
