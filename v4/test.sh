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

printf '\n%s=== Testing Components ===%s\n' "$components_color" "$reset"
"$root_dir/Components/test.sh" "$@"
printf '\n%s=== Testing Features ===%s\n' "$features_color" "$reset"
"$root_dir/Features/test.sh" "$@"
for package in Editor Service; do
  printf '\n=== Testing %s ===\n' "$package"
  swift test --package-path "$root_dir/$package" "$@"
done
