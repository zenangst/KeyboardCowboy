# MachPortSystem

## Live event tap probe

Use a logged-in macOS session with Input Monitoring and Accessibility granted
to the runner. Open a blank, disposable TextEdit document. From `v4`, run:

```sh
swift run --package-path Components/MachPortSystem -c release \
  EventTapProbe "$(pgrep -x TextEdit)"
```

Follow the spoken cues:

1. **Tap ready:** Focus TextEdit, tap and release left Shift, then tap and release
   the physical A key without modifiers. Keep TextEdit focused and don't type
   while the probe posts its own unmodified A key pair.
2. **Primary tap stopped:** Tap and release A once more, then wait for the result.

The probe passes events through. It posts one tagged key pair only if TextEdit is
frontmost and the modifiers are released. A second tap independently verifies
that the posted pair arrived without reaching the primary handler, and that
physical events still arrive after the primary tap stops. The probe counts
only the requested test events and does not log typed text. Discard the
document afterward.

Exit codes: `0` passed, `1` failed, `2` inconclusive or setup incomplete.

### Timeout and recovery

Run the same command with `--timeout` after the PID. This mode posts no
synthetic input. It deliberately stalls only the probe's primary callback,
once, for two seconds to exercise the macOS timeout. At each spoken cue,
tap and release A exactly once and wait. Keep the disposable document focused;
do not use this mode during other work. The witness tap checks that input
still arrives while the primary tap is disabled and after it stops. The probe
reloads outside the callback and checks that the primary tap delivers exactly
one key-down and key-up after recovery.

### Permission checks

Build the disposable probe app and move it into `/Applications` so it can
have its own permission entries. Leave all other apps' permissions unchanged.

```sh
staging=$(mktemp -d)
sh Components/MachPortSystem/Tools/build-permission-probe.sh "$staging"
```

Before granting anything, check both permissions without installing a tap:

```sh
app='/Applications/Cowboy Event Tap Probe.app'
log=$(mktemp)
open -n -W --stdout "$log" "$app" --args --permissions
cat "$log"
```

Grant **Input Monitoring** only to **Cowboy Event Tap Probe**, leaving its
Accessibility permission off. Repeat the status check to verify that listening
is allowed and posting is denied. On the tested macOS version, this was
insufficient to create an active tap. Enable Accessibility for the same probe
and confirm both preflights pass. Then open a disposable TextEdit document and
run:

```sh
log=$(mktemp)
open -n -W --stdout "$log" "$app" \
  --args "$(pgrep -x TextEdit)" --revoke-input-monitoring
cat "$log"
```

Follow the spoken cues. If the operating system asks to quit the probe after
revocation, choose **Later** if available. Confirm the final physical key
reaches TextEdit; silence in the tap alone does not prove it was pressed.
Leave Input Monitoring off and repeat `--permissions` in a fresh process to
distinguish live revocation from revocation that takes effect on relaunch.
In the observed run, the installed tap still received input after revocation;
the fresh launch reported listening denied and posting still allowed. The
probe never requests permission or posts events in these modes.

To check posting separately, leave the probe's Input Monitoring off and its
Accessibility on. Launch the disposable app with `--revoke-posting` instead of
`--permissions`. At the spoken cue, turn off Accessibility only for the
probe. If macOS offers **Later**, choose it to let the process finish. Repeat
`--permissions` in a fresh process with both permissions off. This measures
preflight status only; it does not install a tap or attempt to post input.
In the observed run, the running process still reported posting allowed
after the toggle, but a fresh process reported posting denied.

Remove only the dedicated probe's permission entries and app afterward.
