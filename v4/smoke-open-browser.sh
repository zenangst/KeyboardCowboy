#!/bin/bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
app="$root_dir/Service/.build/app/debug/Keyboard Cowboy.app"

usage() {
  printf '%s\n' \
    "Usage: $0 --build" \
    "       $0 --logs" \
    "       $0 <bundle-id> <http-or-https-url>"
}

if [[ $# -eq 1 ]]; then
  case "$1" in
    --build) exec env CONFIGURATION=debug "$root_dir/Scripts/build-app.sh" ;;
    --logs) exec /usr/bin/log stream --predicate 'subsystem == "com.zenangst.keyboardcowboy.v4" AND category == "BrowserSmoke"' ;;
    -h|--help) usage; exit 0 ;;
  esac
fi

if [[ $# -ne 2 || "$1" == -* || ( "$2" != http://* && "$2" != https://* ) ]]; then
  usage >&2
  exit 2
fi

if [[ ! -x "$app/Contents/MacOS/KeyboardCowboy" ]]; then
  printf 'Debug Service app not built. Run %s --build first.\n' "$0" >&2
  exit 1
fi

exec /usr/bin/open -n "$app" --args --smoke-open-browser "$1" "$2"
