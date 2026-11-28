#!/bin/bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

python3 - "$root_dir" <<'PY'
import json
import os
from pathlib import Path
import subprocess
import sys

root = Path(sys.argv[1])
key = "XCODEBUILD_DESTINATION_ID"
destination = os.environ.get(key, "")
env_file = root / ".env"
if not destination and env_file.is_file():
    for line in env_file.read_text().splitlines():
        name, sep, value = line.strip().partition("=")
        if sep and name == key:
            destination = value.strip().strip("\"'")
if not destination:
    sys.exit(f"Set {key}=<My Mac destination ID> in {env_file}.")

created = skipped = failed = 0
for directory, dirs, files in os.walk(root):
    dirs[:] = sorted(name for name in dirs if not name.startswith(".") and name != "tmp")
    if "Package.swift" not in files:
        continue

    package = Path(directory)
    settings_file = package / ".nvim/xcodebuild/settings.json"
    if settings_file.exists():
        skipped += 1
        continue

    try:
        result = subprocess.run(
            ["xcodebuild", "-list", "-json", "-skipPackageUpdates"],
            cwd=package, text=True, stdout=subprocess.PIPE, check=True,
        )
        workspace = json.loads(result.stdout)["workspace"]
        name, schemes = workspace["name"], workspace["schemes"]
        scheme = next((s for s in (name, f"{name}-Package") if s in schemes), None)
        if scheme is None and len(schemes) == 1:
            scheme = schemes[0]
        if scheme is None:
            raise ValueError(f"cannot pick a scheme from {schemes}")

        settings_file.parent.mkdir(parents=True, exist_ok=True)
        with settings_file.open("x") as output:
            json.dump({
                "platform": "macOS",
                "workingDirectory": str(package),
                "swiftPackage": str(package / "Package.swift"),
                "deviceName": "My Mac",
                "destination": destination,
                "scheme": scheme,
            }, output, indent=2)
            output.write("\n")
    except FileExistsError:
        skipped += 1
        continue
    except (OSError, KeyError, ValueError, subprocess.CalledProcessError) as error:
        print(f"{package.relative_to(root)}: {error}", file=sys.stderr)
        failed += 1
        continue

    created += 1
    print(f"Configured {package.relative_to(root)} ({scheme})")

print(f"Created {created}; kept {skipped} existing; failed {failed}.")
sys.exit(bool(failed))
PY
