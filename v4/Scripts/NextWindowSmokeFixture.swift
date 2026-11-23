import AppKit

@main
@MainActor
struct NextWindowSmokeFixture {
  static func main() {
    guard CommandLine.arguments.count == 3 else { exit(2) }

    let app = NSApplication.shared
    app.setActivationPolicy(.regular)
    app.finishLaunching()
    let service = CommandLine.arguments[1]
    let result = URL(fileURLWithPath: CommandLine.arguments[2])

    DispatchQueue.main.asyncAfter(deadline: .now() + 20) {
      try? "FAIL: timed out waiting for the Service\n".write(to: result, atomically: true, encoding: .utf8)
      app.terminate(nil)
    }
    Task { @MainActor in
      let message = await check(app, service: service)
      try? (message + "\n").write(to: result, atomically: true, encoding: .utf8)
      app.terminate(nil)
    }
    app.run()
  }

  static func check(_ app: NSApplication, service: String) async -> String {
    guard let screen = NSScreen.main else { return "FAIL: no screen for fixture" }

    let frame = NSRect(x: screen.visibleFrame.minX + 50, y: screen.visibleFrame.minY + 80, width: 320, height: 180)
    let windows = (1 ... 3)
      .map { number in
        let window = NSWindow(contentRect: frame, styleMask: [.titled, .closable, .miniaturizable],
                              backing: .buffered, defer: false)
        window.title = "Next Window Test \(number)"
        window.isReleasedWhenClosed = false
        window.orderFrontRegardless()
        return window
      }
      .sorted { $0.windowNumber < $1.windowNumber }
    defer { windows.forEach { $0.close() } }

    windows[0].makeKeyAndOrderFront(nil)
    app.activate()
    let pid = getpid()
    do {
      try await Task.sleep(for: .milliseconds(500))
      guard app.isActive, windows[0].isKeyWindow else { return "FAIL: fixture did not become active" }

      for index in [1, 2, 0] {
        try await expectKeyWindow(windows[index], service: service, pid: pid, scenario: "cycle")
      }

      windows[2].makeKeyAndOrderFront(nil)
      let history = ["--smoke-previous-window", String(pid), String(windows[2].windowNumber), String(windows[0].windowNumber)]
      try await expectKeyWindow(windows[0], service: service, pid: pid, scenario: "previous history", command: history)

      windows[2].makeKeyAndOrderFront(nil)
      windows[0].miniaturize(nil)
      try await Task.sleep(for: .milliseconds(500))
      guard windows[0].isMiniaturized else { return "FAIL: prior window did not minimize" }

      try await expectKeyWindow(windows[1], service: service, pid: pid, scenario: "previous fallback", command: history)
      guard windows[0].isMiniaturized else { return "FAIL: previous restored a minimized history window" }

      windows[0].deminiaturize(nil)
      try await Task.sleep(for: .milliseconds(500))
      windows[0].makeKeyAndOrderFront(nil)

      // A minimized window can still exist in AX, but must not be raised.
      windows[1].miniaturize(nil)
      try await Task.sleep(for: .milliseconds(500))
      guard windows[1].isMiniaturized else { return "FAIL: fixture window 2 did not minimize" }

      try await expectKeyWindow(windows[2], service: service, pid: pid, scenario: "skip minimized window")
      guard windows[1].isMiniaturized else { return "FAIL: Service restored minimized window 2" }

      windows[0].close()
      try await expectKeyWindow(windows[2], service: service, pid: pid, scenario: "one eligible window")
      guard windows[1].isMiniaturized else { return "FAIL: one-window check restored minimized window 2" }

      windows[1].deminiaturize(nil)
      try await Task.sleep(for: .milliseconds(500))
      windows[2].makeKeyAndOrderFront(nil)
      try await expectKeyWindow(windows[1], service: service, pid: pid, scenario: "restored window")
    } catch {
      return "FAIL: \(error); check Accessibility and WindowFocusSmoke logs"
    }
    return "PASS: signed Service cycled, preferred previous focus history, fell back when it was minimized, and handled window eligibility"
  }

  private enum Failure: Error {
    case fixtureInactive
    case launchFailed(Int32)
    case unexpectedFocus(scenario: String, expected: String)
  }

  private static func expectKeyWindow(
    _ window: NSWindow, service: String, pid: pid_t, scenario: String, command: [String]? = nil,
  ) async throws {
    guard NSApp.isActive else { throw Failure.fixtureInactive }

    let status = try await Task.detached {
      // Wait for the one-shot launch without blocking the fixture's AX run loop.
      let process = Process()
      process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
      process.arguments = ["-g", "-n", "-W", service, "--args"] + (command ?? ["--smoke-next-window", String(pid)])
      try process.run()
      process.waitUntilExit()
      return process.terminationStatus
    }
    .value
    guard status == 0 else { throw Failure.launchFailed(status) }

    try await Task.sleep(for: .milliseconds(150))
    guard NSApp.isActive, window.isKeyWindow else {
      throw Failure.unexpectedFocus(scenario: scenario, expected: window.title)
    }
  }
}
