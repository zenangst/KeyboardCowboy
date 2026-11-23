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
`debug`, and `SIGNING_IDENTITY` defaults to ad hoc (`-`). The service does not
install event taps or execute workflows yet.

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
Release builds do not recognize this launch option.

To test a running Safari or Orion web app, pass its bundle identifier and a
URL within the app's site to the same script. With one AX window, expect
`Web-app polling skipped: at most one AX window`. With multiple windows, leave
the target page in a background window and check for
`Web-app AX main and raise succeeded`, then confirm that window came forward.
The log distinguishes a polling miss from a route failure and generic fallback.

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
