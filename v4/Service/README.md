# Keyboard Cowboy v4 service

From the repository root, build the standalone Editor and run the service:

```sh
v4/Editor/Scripts/build-app.sh
swift run --package-path v4/Service
```

**Edit Configuration…** in the keyboard menu-bar item opens the separately
built Editor. The service itself also starts without the Editor build.

To assemble and launch the combined app:

```sh
app="$(v4/Scripts/build-app.sh)"
open "$app"
```

The script signs the Editor before the outer app. `CONFIGURATION` defaults to
`debug`. An explicit `SIGNING_IDENTITY` takes precedence; otherwise Debug builds
use the repository-local identity below when configured. Other builds, and
Debug builds without a configured identity, default to ad hoc signing (`-`).
The service does not install event taps or execute workflows yet.

### Live keyboard layout refresh smoke test

No manual layout setup is needed. From the repository root, run:

```sh
KC_LAYOUT_SMOKE=1 swift test --package-path v4/Service -c release \
  --filter liveKeyboardLayoutRefresh
```

The test temporarily switches to built-in French or US and checks that the
running Service layout session refreshes its cache. It restores the original
selection and disables the test source only if it was enabled for the test.
No event tap or keystrokes are used. Avoid changing input sources while it runs.

### Live input method fallback smoke test

Select an input method without Unicode layout data, such as **Japanese —
Romaji** in **Hiragana** mode. Keep it selected while the test runs from the
repository root:

```sh
KC_IME_FALLBACK_SMOKE=1 swift test --package-path v4/Service -c release \
  --filter liveKeyboardIMEFallback
```

The test compares unmodified key translations against the underlying macOS
keyboard layout. It does not change the input source, install a tap, or post
input. Switch back to your usual input source afterward.

### Live keyboard hardware refresh smoke test

Start with one keyboard in use and have a second keyboard that macOS reports
as a different hardware type (for example, ANSI versus ISO) ready to connect.
Keep the same input source selected. From the repository root:

```sh
KC_KEYBOARD_HARDWARE_SMOKE=1 swift test --package-path v4/Service -c release \
  --filter liveKeyboardHardwareRefresh
```

At the spoken cue, connect the other keyboard and tap and release Shift on it.
The test checks that an explicit refresh uses the new macOS keyboard type.
It does not install an event tap, post keys, or test automatic hardware-change
notifications. If macOS reports no type change, the result is inconclusive.

### Live shortcut posting smoke test

Focus a blank, disposable TextEdit document with the caret in its body. With
Accessibility and event posting access granted to the runner, run from the
repository root without switching focus:

```sh
KC_SHORTCUT_POSTING_SMOKE=1 swift test --package-path v4/Service -c release \
  --filter liveShortcutPosting
```

The test posts one **Left Shift+A** through the cached-layout shortcut
executor and checks that exactly `A` appears in the same document. Discard
the document afterward.

### Live shortcut recording smoke test

Grant the runner Accessibility and Input Monitoring, then run from the
repository root:

```sh
KC_SHORTCUT_RECORDING_SMOKE=1 swift test --package-path v4/Service -c release \
  --filter liveShortcutRecording
```

Use a disposable text field and press **Left Shift+A** once at each spoken
cue: **Capture ready** checks key delivery and **Recorder ready** checks
shortcut decoding. The test does not log or save the captured input. The
keystroke passes through to the foreground app. Escape cancels, and the
recorder stops after 20 seconds if no shortcut is captured.

### Live TextEdit typing smoke test

Grant event posting and Accessibility access to the runner, then focus the
text area of a blank, disposable TextEdit document. No layout setup is needed.
Run from the repository root without switching foreground apps:

```sh
KC_TEXTEDIT_TYPING_SMOKE=1 swift test --package-path v4/Service -c release \
  --filter liveTextEditTyping
```

The smoke test switches through **US, Norwegian, and Swedish Pro** and
uses the Text command's **Typing** mode to append one line per layout to
the same document. The US line includes all ten Nordic letters
(`åæøäö ÅÆØÄÖ`). Each step checks the cumulative text without logging it,
and the last step checks the complete document. The test restores the
original input source and disables only sources it temporarily enabled.
It does not save the document or change the clipboard.
Turn off **Capitalize words automatically** in macOS Text Input settings
for an exact lowercase check; Typing does not disable editor substitutions.

To keep the Debug app's signing requirement stable across rebuilds, choose a
named identity from `security find-identity -v -p codesigning` and store its
exact name for this checkout:

```sh
git config --local keyboardcowboy.debugSigningIdentity 'Developer ID Application: Your Name (TEAMID)'
```

Rebuild and re-add the exact Debug bundle in System Settings → Privacy &
Security → Accessibility when switching from ad hoc signing. Keep the same
identity, bundle identifier, and app path for subsequent smoke tests.

`HostOpen` composes the Open command for the future workflow runner. It accepts
an already-resolved path and leaves host interception to the caller. Browser
reuse tries Accessibility first, then uses Apple Events for tab search on a
clean miss. The default web-app route uses Accessibility to make matching
windows main and raise them.

### Debug browser smoke test

From `v4`, build the Debug app once and start the log stream in another
terminal:

```sh
./smoke-open-browser.sh --build
./smoke-open-browser.sh --logs
```

Run `./smoke-open-browser.sh --check-accessibility` to see whether the packaged
Service is trusted. It reports to the same log stream without requesting
permission or opening a browser.

With Safari already running, launch a one-shot instance of the packaged Service:

```sh
./smoke-open-browser.sh com.apple.Safari \
  'https://example.com/?kc-smoke=match'
```

Repeat with `com.google.Chrome` or `org.chromium.Chromium`. Grant Accessibility
to the packaged Service in System Settings for the first two cases, and allow
Automation when macOS prompts for tab search.

| Setup | Expected result |
| --- | --- |
| URL is active in a background browser window | Window comes forward; `browser route succeeded` without `tab search started`. |
| URL is only in an inactive tab | `tab search started`, then `browser route succeeded`; the tab becomes active. |
| Accessibility is denied, browser is running | `browser route failed`, then `generic open started`, with no `tab search started`. |

The smoke instance quits after one command. Logs omit URLs and window titles.

To test a running Safari or Orion web app, pass its bundle identifier and a
URL within the app's site to the same script. With one AX window, expect
`Web-app polling skipped: at most one AX window`. With multiple windows, leave
the target page in a background window and check for
`Web-app AX main and raise succeeded`, then confirm that window came forward.
The log distinguishes a polling miss from a route failure and generic fallback.

### Debug window-ID smoke test

Run this read-only check from the repository root. Set `pid` to the PID of a
running app with an open window. Grant Accessibility to the exact Debug bundle
if the log says `Accessibility trusted: false`; the check does not prompt.

```sh
app="$(v4/Scripts/build-app.sh)"
open -g -n -W "$app" --args --smoke-window-id "$pid"
log show --last 1m --style compact \
  --predicate 'subsystem == "com.zenangst.keyboardcowboy.v4" AND category == "WindowIDSmoke"'
```

The result reports AX windows, matching CG owners, lookup misses, IDs absent
from the fresh CG snapshot, and wrong owners. It does not log individual IDs
or titles, raise a window, or post input. Repeat after closing a window or
changing Spaces. A match verifies ownership in the current snapshot, not that
the window is on the active Space or that the association remains valid later.
Release builds do not recognize this launch option.

### Debug next-window smoke test

For an automated check, grant Accessibility to the signed Debug bundle, then
run `v4/Scripts/smoke-next-window.sh` from the repository root. This opens a
disposable AppKit fixture with three windows at identical positions. It checks
cycling and wraparound, prefers the last focused window for Previous Window,
and falls back to reverse cycling when that window is minimized. It also
checks that a lone eligible window keeps focus and a restored window rejoins
the cycle.
The fixture briefly takes focus; leave it frontmost until the script finishes.
Pass the bundle path as the only argument to test a different signed Debug
artifact. The script prints the macOS version and exits nonzero on failure.

Use `v4/Scripts/smoke-next-window.sh --spatial [app-path]` to check center
focus, two top-left presses on overlapping windows (Focus Behind), and rightward
focus from both unequal left windows to a target at the top, middle, and bottom.
On a display with at least 1010×770 visible points, it also checks all 16 hops
around a nine-window grid and out-and-back from its center in all four directions.
The smoke operation only targets the fixture process and checks actual AppKit
key-window changes. Keep at least 880×540 visible points on the starting screen
and leave the fixture frontmost during the spoken cues.

For required cross-display verification, run
`v4/Scripts/smoke-next-window.sh --multi-display [app-path]`. This exits nonzero
unless two separate displays can fit three windows along both facing edges.
It verifies all three crossings in both directions for the connected layout,
using actual window positions to predict the next row or column. Rearrange
the displays and rerun to cover a different axis.

Use `v4/Scripts/smoke-next-window.sh --cross-app [app-path]` for app-to-app
focus. Right must activate the disposable peer app and make its target
window key instead of its previously focused decoy; Left must return to the
original app and window. The smoke limits selection to the two fixture
processes and requires at least 920×590 visible points.

If you use yabai, add a fixture-only rule before launching the smoke test so
yabai does not tile the test windows:

```sh
yabai -m rule --add label=kc-smoke-fixtures app='^(Center Fixture|Next Window Fixture|Next Window Peer)$' manage=off
```

This rule lasts until yabai restarts. To remove it sooner, run
`yabai -m rule --remove kc-smoke-fixtures`. It isolates the fixtures from
tiling; it does not guarantee that the smoke test passes.

The same rule covers the standalone Fill timing probe. Run
`v4/Scripts/smoke-window-fill.sh` from an Accessibility-trusted terminal and
leave the disposable fixture frontmost until the probe finishes. It compares
AX readback and Core Graphics bounds across several delays. The shorter
samples are diagnostic; the 500 ms controls and the bounded CG-settling
checks must reach the expected frames.
The settling checks exercise the Window Management Fill API and verify the
result against the fixture's own window ID in Core Graphics. They also
switch focus to a second fixture window after the move and verify that
neither window is resized. Pass `secondary` to run just those checks on
the first extended display after the primary. The probe prints that display's
AX bounds. Set `CONFIGURATION=release` to exercise the optimized feature
build. The fixture also checks that directional Move preserves the window's
size, that top-leading Grow and Shrink reverse each other, and that shrinking
at a display edge preserves the opposite edges and reports any fixture
minimum-size clamp. It also verifies a position-only Center toggle,
explicit Fill restore from a centered frame, and a Fill toggle round trip
from a frame near a display edge.
The unrestricted fixture also checks a bottom-trailing Anchor snap and
cycles through all three size bands. A top-edge cycle in a smaller snap
area checks that Anchor honors the fixture's known minimum height and
can continue cycling when the app clamps a band without a supplied minimum.
The standalone repeat session also checks that resetting starts a fresh snap.
With exactly two displays it checks both centered and proportional
display-transfer round trips. The test does not run the Service or a saved
workflow.

To smoke-test native Dynamic Quarters, put exactly four disposable,
unmanaged Finder windows on the second display in the current Space, with
no other windows on that display. Leave one focused and run from the
repository root without switching foreground apps:

```sh
KC_TILING_DYNAMIC_SMOKE=1 swift test --package-path v4/Features/WindowTiling \
  -c release --filter liveDynamicQuarters
```

The runner needs Accessibility permission. It rearranges the windows, seeds
native Quarters, then switches focus between tiles and checks both Dynamic
Quarters directions. It leaves the resulting layout in place.

To smoke-test another app manually:

Build the Debug app as above and grant it Accessibility. Put at least two
ordinary windows of the same test app on the current Space, set `pid` to that
app's PID, and leave it frontmost when running the command (for example, run
it from a separate terminal session without bringing the terminal forward):

```sh
open -g -n -W "$app" --args --smoke-next-window "$pid"
log show --last 1m --style compact \
  --predicate 'subsystem == "com.zenangst.keyboardcowboy.v4" AND category == "WindowFocusSmoke"'
```

Run repeatedly to check that the same windows cycle and wrap. The command
raises at most one window, only if the specified app is still active and the
current and target windows are still verified on-screen. With one eligible
window or a different active app, expect `Next window raise succeeded: false`.
It does not activate an app, post input, or cache window IDs. Standard Release
builds do not recognize this launch option.

To test Previous Window, replace the launch arguments with
`--smoke-previous-window "$pid" "$current_id" "$previous_id"`. The history IDs
are supplied explicitly because each smoke invocation is a new process.
Omit both IDs to test reverse cycling without history.

#### Opt-in Window Focus validation build

To check the private bridge in a distribution-style build without enabling it
in standard Release, build a separate optimized, hardened-runtime bundle.
Set `developer_id` to your Developer ID Application signing identity:

```sh
app="$(CONFIGURATION=release WINDOW_FOCUS_VALIDATION=1 SIGNING_IDENTITY="$developer_id" v4/Scripts/build-app.sh)"
v4/Scripts/smoke-next-window.sh "$app"
```

The candidate is under `v4/Service/.build/app/window-focus-validation/`. It
contains only the next-, previous-, and spatial-focus smoke commands, not the other
Debug commands.
Grant Accessibility to the exact candidate if needed. Notarization is not
required for this validation. Keep this artifact separate from builds intended
for distribution; notarize the app when it is ready to ship.

### Debug hit-test smoke check

From `v4`, build the Debug app and grant that bundle Accessibility access.
Then run:

```sh
open -g -n -W 'Service/.build/app/debug/Keyboard Cowboy.app' --args --smoke-hit-test
log show --last 1m --style compact \
  --predicate 'subsystem == "com.zenangst.keyboardcowboy.v4" AND category == "HitTestSmoke"'
```

Move the pointer over a known control within five seconds of launch. The
check logs the AX point and role, not the control's title or contents. Try
a button on the primary display, then repeat on a secondary display arranged
to the left or above it. Check that the role matches the control and that
the corresponding coordinate is negative on the secondary display. For a
control that exposes geometry, its AX frame should contain the pointer.

### Debug Command-click capture smoke check

From `v4`, grant the packaged Debug Service Accessibility and Input
Monitoring, then run:

```sh
open -g -n -W 'Service/.build/app/debug/Keyboard Cowboy.app' --args --smoke-capture
log show --last 1m --style compact \
  --predicate 'subsystem == "com.zenangst.keyboardcowboy.v4" AND category == "CaptureSmoke"'
```

Command-click a harmless control within 15 seconds. The Service suppresses
the click and logs the control’s role and frame, not its title or contents.
Press Escape to cancel. The smoke instance stops its tap and quits after one
result, cancellation, disruption, or timeout.

Add `--show-in-editor` after `--smoke-capture` to open a read-only preview
in a separate bundled Debug Editor instance. The Service stops the capture tap
before opening the preview and passes only the role and frame, not an AX handle.

### Debug UI-element activation smoke check

With the packaged Debug Service trusted, focus a Safari window with its
sidebar hidden. Run from `v4` without bringing the terminal to the front
(or add `sleep 5;` before `open` and switch back to Safari):

```sh
open -g -n -W 'Service/.build/app/debug/Keyboard Cowboy.app' --args --smoke-ui-element
log show --last 1m --style compact \
  --predicate 'subsystem == "com.zenangst.keyboardcowboy.v4" AND category == "UIElementSmoke"'
```

The check matches an English Safari button whose Accessibility title or
description contains `Sidebar` or `sidebar`. Expect the sidebar to open and
`UIElement activated: true` in the log. Append `--miss` for a nonmatching predicate;
it should log `UIElement activated: false` without changing the window.

If the button does not activate, append `--inspect` instead and hover over
**Show Sidebar** within five seconds. This read-only mode reports whether
the hovered role and label match the predicate and whether the focused-window
search found it. It does not log the label itself.

For the click-and-restore path, run the same `open` command with
`--smoke-static-text` instead. Keep the **Static Text Click Smoke Test** window
focused and move the pointer outside it within five seconds. Hold the pointer
still until the window reports the result. A pass shows `Clicks: 1` and confirms
that the pointer returned to its original position. Close the window to exit.

Append `--mouse-post left`, `--mouse-post right`, or `--mouse-post double`
to exercise Mouse event posting in the same fixture. A pass also verifies
the delivered mouse button and click state.

### Debug text-range geometry smoke check

Focus a disposable TextEdit document, select some text, then run from `v4`:

```sh
open -g -n -W 'Service/.build/app/debug/Keyboard Cowboy.app' --args --smoke-selected-text --bounds
log show --last 1m --style compact \
  --predicate 'subsystem == "com.zenangst.keyboardcowboy.v4" AND category == "SelectedTextSmoke"'
```

Repeat with an empty selection. The log reports the AX screen bounds and
whether the range is a caret. This mode does not read the text or post clicks.

For Xcode, focus a source editor with a selection and use `--xcode-anchors`
instead of `--bounds`. The log reports the leading, center, and trailing
target points without editing the document or posting clicks.
