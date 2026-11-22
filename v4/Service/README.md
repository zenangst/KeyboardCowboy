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
