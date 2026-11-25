# AccessibilitySystem

## Live window observer probe

Use a logged-in macOS session, a terminal with Accessibility permission, and
TextEdit with at least one disposable document window and no unsaved work.
Run the probe as a standalone executable so it owns its main run loop. From
`v4`:

```sh
swift run --package-path Components/AccessibilitySystem -c release \
  WindowObservationProbe "$(pgrep -x TextEdit)"
```

Follow the spoken cues. By default, open a separate window in each of the
three phases and leave the windows open; the probe checks delivery before and
after restart and silence while stopped. If Command-N opens a tab, use
**Window → Move Tab to New Window**. Pass `--destruction` to instead close one
window (start with at least two). App-level destruction events invalidate the
inventory; they do not map one-to-one to window closures. Pass `--termination`
to quit and reopen TextEdit, then verify delivery on its new PID.

The probe does not log window titles or contents or request AX permission.
Exit codes: `0` passed, `1` failed, `2` inconclusive or setup incomplete.

### Permission revocation

Build the disposable app into a writable staging directory, then move it to
`/Applications` so it appears as its own entry in System Settings:

```sh
staging=$(mktemp -d)
sh Components/AccessibilitySystem/Tools/build-revocation-probe.sh "$staging"
```

In **System Settings → Privacy & Security → Accessibility**, add and enable
**Cowboy AX Revocation Probe**. If it does not appear as its own entry, stop;
do not revoke Terminal, OpenCode, or any other app as a substitute. With
TextEdit open, launch the installed app through Launch Services:

```sh
log=$(mktemp)
open -n -W --stderr "$log" '/Applications/Cowboy AX Revocation Probe.app' \
  --args "$(pgrep -x TextEdit)" --revocation
cat "$log"
```

At the spoken cue, turn off **only** the probe's entry. Leave TextEdit running.
The probe checks for loss of trust, an `apiDisabled` read, and safe, idempotent
observer teardown. Remove the permission entry and the disposable app afterward.
