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
an already-resolved path and leaves host interception and web-app handling to
the caller. Browser reuse tries Accessibility first, then uses Apple Events
for tab search on a clean miss.

### Debug browser smoke test

From `v4`, build the Debug app once and start the log stream in another
terminal:

```sh
./smoke-open-browser.sh --build
./smoke-open-browser.sh --logs
```

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
