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
      try? "FAIL: timed out waiting for the Debug Service\n".write(to: result, atomically: true, encoding: .utf8)
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
    let windows = (1...3).map { number in
      let window = NSWindow(contentRect: frame, styleMask: [.titled, .closable], backing: .buffered, defer: false)
      window.title = "Next Window Test \(number)"
      window.isReleasedWhenClosed = false
      window.orderFrontRegardless()
      return window
    }.sorted { $0.windowNumber < $1.windowNumber }
    defer { windows.forEach { $0.close() } }

    windows[0].makeKeyAndOrderFront(nil)
    app.activate()
    let pid = getpid()
    var passed = 0
    do {
      try await Task.sleep(for: .milliseconds(500))
      guard app.isActive, windows[0].isKeyWindow else { return "FAIL: fixture did not become active" }
      for index in [1, 2, 0] {
        guard app.isActive else { return "FAIL: fixture lost focus; rerun without switching apps" }
        let status = try await Task.detached {
          // Wait for the one-shot launch without blocking the fixture's AX run loop.
          let process = Process()
          process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
          process.arguments = ["-g", "-n", "-W", service, "--args", "--smoke-next-window", String(pid)]
          try process.run()
          process.waitUntilExit()
          return process.terminationStatus
        }.value
        guard status == 0 else { return "FAIL: Service launch exited with \(status)" }
        try await Task.sleep(for: .milliseconds(150))
        guard app.isActive, windows[index].isKeyWindow else {
          return "FAIL: expected fixture window \(index + 1) after \(passed) successful raises; check Accessibility and WindowFocusSmoke logs"
        }
        passed += 1
      }
    } catch {
      return "FAIL: \(error)"
    }
    return "PASS: signed Service focused windows 1 → 2 → 3 → 1"
  }
}
