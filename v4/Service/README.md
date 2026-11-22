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
