# AccessibilitySystem

## Live window observer smoke test

Use a logged-in macOS session, a terminal/test runner with Accessibility
permission, and a separate test app such as TextEdit. Leave two disposable
windows open so you can switch focus. From `v4`, run:

```sh
KC_AX_WINDOW_OBSERVATION_PID=12345 swift test \
  --package-path Components/AccessibilitySystem -c release \
  --filter liveWindowObservation
```

Replace `12345` with the target's numeric PID from Activity Monitor. Follow
the terminal's prompts to open, focus, and close disposable windows during the
initial, stopped, and restarted observation phases. The test checks creation
and focus delivery before and after restart and checks that the old callback
stays silent. It reports app-level element destruction delivery without
assuming every app emits it. It does not log window titles or contents, prompt
for permissions, or wire observation into the Service.
