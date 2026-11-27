import AppKit

@main
@MainActor
struct NextWindowSmokeFixture {
  static func main() {
    let arguments = CommandLine.arguments
    if arguments.count == 6, arguments[1] == "--peer",
       let x = Double(arguments[3]), let y = Double(arguments[4]), let owner = pid_t(arguments[5]) {
      runPeer(state: URL(fileURLWithPath: arguments[2]), origin: .init(x: x, y: y), owner: owner)
      return
    }
    let spatial = arguments.count == 4 && arguments[3] == "--spatial"
    let multiDisplay = arguments.count == 4 && arguments[3] == "--multi-display"
    let crossApp = arguments.count == 4 && arguments[3] == "--cross-app"
    guard arguments.count == 3 || spatial || multiDisplay || crossApp else { exit(2) }

    let app = NSApplication.shared
    app.setActivationPolicy(.regular)
    app.finishLaunching()
    let service = CommandLine.arguments[1]
    let result = URL(fileURLWithPath: CommandLine.arguments[2])

    DispatchQueue.main.asyncAfter(deadline: .now() + (spatial || multiDisplay ? 150 : 20)) {
      try? "FAIL: timed out waiting for the Service\n".write(to: result, atomically: true, encoding: .utf8)
      app.terminate(nil)
    }
    Task { @MainActor in
      let message = if crossApp {
        await checkCrossApp(app, service: service, directory: result.deletingLastPathComponent())
      } else if multiDisplay {
        await checkDisplayEdges(app, service: service)
      } else if spatial {
        await checkSpatial(app, service: service)
      } else {
        await check(app, service: service)
      }
      try? (message + "\n").write(to: result, atomically: true, encoding: .utf8)
      app.terminate(nil)
    }
    app.run()
  }

  private static func crossAppWindow(_ title: String, at origin: CGPoint) -> NSWindow {
    let window = NSWindow(contentRect: CGRect(origin: origin, size: CGSize(width: 330, height: 220)),
                          styleMask: [.titled, .closable], backing: .buffered, defer: false)
    window.title = title
    window.isReleasedWhenClosed = false
    window.orderFrontRegardless()
    return window
  }

  private final class PeerKeyReporter: NSObject, NSWindowDelegate {
    let state: URL

    init(state: URL) { self.state = state }

    func windowDidBecomeKey(_ notification: Notification) {
      guard let window = notification.object as? NSWindow else { return }
      try? window.title.write(to: state, atomically: true, encoding: .utf8)
    }
  }

  private static func runPeer(state: URL, origin: CGPoint, owner: pid_t) {
    let app = NSApplication.shared
    app.setActivationPolicy(.regular)
    app.finishLaunching()
    let target = crossAppWindow("Peer target", at: origin)
    let decoy = crossAppWindow("Peer decoy", at: CGPoint(x: origin.x, y: origin.y + 270))
    let reporter = PeerKeyReporter(state: state)
    target.delegate = reporter
    decoy.delegate = reporter
    decoy.makeKeyAndOrderFront(nil)
    app.activate()
    Task { @MainActor in
      for _ in 0 ..< 20 {
        if app.isActive, decoy.isKeyWindow, let fixture = NSRunningApplication(processIdentifier: owner) {
          // Cooperate only during setup. The two Service hops must work unaided.
          app.yieldActivation(to: fixture)
          try? "ready".write(to: state.appendingPathExtension("ready"), atomically: true, encoding: .utf8)
          return
        }
        do {
          try await Task.sleep(for: .milliseconds(100))
        } catch {
          return
        }
      }
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 25) { app.terminate(nil) }
    withExtendedLifetime((target, decoy, reporter)) { app.run() }
  }

  private static func checkCrossApp(_ app: NSApplication, service: String, directory: URL) async -> String {
    guard let screen = NSScreen.main, screen.visibleFrame.width >= 920, screen.visibleFrame.height >= 590 else {
      return "FAIL: cross-app fixture requires a 920×590 visible display"
    }
    let visible = screen.visibleFrame
    let origin = CGPoint(x: visible.minX + 45, y: visible.minY + 45)
    let anchor = crossAppWindow("Fixture anchor", at: origin)
    defer { anchor.close() }
    let state = directory.appendingPathComponent("peer-key")
    let peerURL = directory.appendingPathComponent("Next Window Peer.app")
    let options = NSWorkspace.OpenConfiguration()
    options.createsNewApplicationInstance = true
    options.arguments = ["--peer", state.path, String(Double(origin.x + 470)), String(Double(origin.y)), String(getpid())]
    func waitForFocus(_ predicate: () -> Bool) async throws -> Bool {
      for _ in 0 ..< 20 {
        if predicate() { return true }
        try await Task.sleep(for: .milliseconds(100))
      }
      return false
    }
    func peerKey() -> String? { try? String(contentsOf: state, encoding: .utf8) }
    do {
      let peer = try await NSWorkspace.shared.openApplication(at: peerURL, configuration: options)
      defer { _ = peer.terminate() }
      guard try await waitForFocus({
        NSWorkspace.shared.frontmostApplication == peer && peerKey() == "Peer decoy"
          && FileManager.default.fileExists(atPath: state.appendingPathExtension("ready").path)
      })
      else { return "FAIL: peer decoy did not become key during setup" }

      anchor.makeKeyAndOrderFront(nil)
      _ = NSRunningApplication.current.activate(from: peer)
      guard try await waitForFocus({ app.isActive && anchor.isKeyWindow }) else { throw Failure.fixtureInactive }
      let a = String(getpid())
      let b = String(peer.processIdentifier)
      try await launchService(service, command: ["--smoke-spatial-focus", a, "right", b])
      guard try await waitForFocus({ NSWorkspace.shared.frontmostApplication == peer && peerKey() == "Peer target" })
      else { return "FAIL: Right did not focus Peer target; last peer key window: \(peerKey() ?? "none")" }

      try await launchService(service, command: ["--smoke-spatial-focus", b, "left", a])
      guard try await waitForFocus({ app.isActive && anchor.isKeyWindow }) else {
        return "FAIL: Left did not return to Fixture anchor"
      }
      return "PASS: cross-app Right focused Peer target instead of the decoy; Left returned to Fixture anchor"
    } catch {
      return "FAIL: \(error); check Accessibility and SpatialFocusSmoke logs"
    }
  }

  private static func checkDisplayEdges(_ app: NSApplication, service: String) async -> String {
    let screens = NSScreen.screens
    guard screens.count >= 2 else { return "FAIL: two separate displays are required" }

    func edgeWindows(in screen: NSScreen, edge: String) -> [NSWindow] {
      let bounds = screen.visibleFrame.insetBy(dx: 10, dy: 10)
      let verticalEdge = edge == "left" || edge == "right"
      let size = CGSize(width: 320, height: 230)
      guard bounds.width >= size.width, bounds.height >= size.height,
            verticalEdge ? bounds.height >= 3 * size.height : bounds.width >= 3 * size.width else { return [] }
      return (0 ..< 3).map { index in
        let fraction = CGFloat(index) / 2
        let x = verticalEdge
          ? (edge == "left" ? bounds.minX : bounds.maxX - size.width)
          : bounds.minX + fraction * (bounds.width - size.width)
        let y = verticalEdge
          ? bounds.maxY - size.height - fraction * (bounds.height - size.height)
          : (edge == "down" ? bounds.minY : bounds.maxY - size.height)
        let window = NSWindow(contentRect: .zero, styleMask: [.titled, .closable], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.setFrame(CGRect(origin: .init(x: x, y: y), size: size), display: false)
        let positions = verticalEdge ? ["top", "middle", "bottom"] : ["left", "middle", "right"]
        window.title = "\(screen.localizedName) \(edge) edge (\(positions[index]))"
        window.orderFrontRegardless()
        return window
      }
    }

    func verify(from anchors: [NSWindow], to targets: [NSWindow], direction: String) async throws {
      let horizontal = direction == "left" || direction == "right"
      for anchor in anchors {
        anchor.makeKeyAndOrderFront(nil)
        app.activate()
        try await Task.sleep(for: .milliseconds(300))
        guard anchor.isKeyWindow, app.isActive else { throw Failure.fixtureInactive }
        // Compare actual perpendicular coordinates (not the slot labels).
        let center = horizontal ? anchor.frame.midY : anchor.frame.midX
        guard let expected = targets.min(by: {
          let first = horizontal ? $0.frame.midY : $0.frame.midX
          let second = horizontal ? $1.frame.midY : $1.frame.midX
          return abs(center - first) < abs(center - second)
        }) else { throw Failure.fixtureInactive }
        try await expectKeyWindow(expected, service: service, pid: getpid(),
                                  scenario: "\(anchor.title) → \(expected.title)",
                                  command: ["--smoke-spatial-focus", String(getpid()), direction])
      }
    }

    var routes: [String] = []
    do {
      for (index, source) in screens.enumerated() {
        let a = source.visibleFrame
        for target in screens.dropFirst(index + 1) {
          let b = target.visibleFrame
          for (outbound, inbound, separated) in [
            ("left", "right", b.maxX <= a.minX), ("right", "left", b.minX >= a.maxX),
            ("up", "down", b.minY >= a.maxY), ("down", "up", b.maxY <= a.minY),
          ] where separated {
            let anchors = edgeWindows(in: source, edge: outbound)
            let targets = edgeWindows(in: target, edge: inbound)
            defer { (anchors + targets).forEach { $0.close() } }
            guard anchors.count == 3, targets.count == 3 else { continue }
            guard anchors.allSatisfy({ $0.screen == source }), targets.allSatisfy({ $0.screen == target }) else {
              return "FAIL: edge windows landed on the wrong display"
            }
            try await verify(from: anchors, to: targets, direction: outbound)
            try await verify(from: targets, to: anchors, direction: inbound)
            routes.append("\(source.localizedName) \(NSStringFromRect(a)) ↔ \(target.localizedName) \(NSStringFromRect(b)): \(outbound)/\(inbound), six verified handoffs")
          }
        }
      }
    } catch {
      return "FAIL: \(error); check Accessibility and SpatialFocusSmoke logs"
    }
    return routes.isEmpty ? "FAIL: no usable display pair with room for three windows along both facing edges"
      : "PASS: matched the expected window for each facing-edge handoff\n\(routes.joined(separator: "\n"))"
  }

  private static func checkSpatial(_ app: NSApplication, service: String) async -> String {
    guard let screen = NSScreen.main, screen.visibleFrame.width >= 880, screen.visibleFrame.height >= 540 else {
      return "FAIL: spatial fixture requires an 880×540 visible display"
    }
    let visible = screen.visibleFrame
    let full = screen.frame
    var windows: [NSWindow] = []
    defer { windows.forEach { $0.close() } }
    func window(_ title: String, x: CGFloat, y: CGFloat, width: CGFloat = 330, height: CGFloat = 235) -> NSWindow {
      let frame = NSRect(x: x, y: y, width: width, height: height)
      let result = NSWindow(contentRect: frame, styleMask: [.titled, .closable], backing: .buffered, defer: false)
      result.title = title
      result.isReleasedWhenClosed = false
      result.orderFrontRegardless()
      windows.append(result)
      return result
    }
    func prepare(_ anchor: NSWindow) async throws {
      anchor.makeKeyAndOrderFront(nil)
      app.activate()
      try await Task.sleep(for: .milliseconds(500))
      guard app.isActive, anchor.isKeyWindow else { throw Failure.fixtureInactive }
    }
    let pid = getpid()
    func command(_ name: String) -> [String] { ["--smoke-spatial-focus", String(pid), name] }

    do {
      let center = window("Center target", x: full.midX - 165, y: full.midY - 118)
      let corner = window("Quarter behind", x: visible.minX + 10, y: visible.maxY - 265)
      let front = window("Quarter front", x: corner.frame.minX, y: corner.frame.minY)
      try await prepare(front)
      try await expectKeyWindow(center, service: service, pid: pid, scenario: "center", command: command("center"))

      let trace = KeyTrace()
      front.delegate = trace
      corner.delegate = trace
      try await expectKeyWindow(corner, service: service, pid: pid, scenario: "repeated quarter", command: command("quarter"))
      guard trace.windows == [front.windowNumber, corner.windowNumber] else {
        return "FAIL: repeated quarter expected \(front.windowNumber) → \(corner.windowNumber), observed \(trace.windows)"
      }
      windows.forEach { $0.orderOut(nil) }

      let taller = window("Tall left anchor", x: visible.minX + 25, y: visible.midY - 170, width: 350, height: 320)
      let shorter = window("Short left anchor", x: visible.minX + 30, y: visible.midY - 35, width: 320, height: 210)
      for (placement, y) in [
        ("top", visible.maxY - 280), ("middle", visible.midY - 120), ("bottom", visible.minY + 20),
      ] {
        let target = window("Right target (\(placement))", x: visible.maxX - 355, y: y)
        for anchor in [taller, shorter] {
          try await prepare(anchor)
          try await expectKeyWindow(target, service: service, pid: pid,
                                    scenario: "\(anchor.title) → \(target.title)", command: command("right"))
        }
        target.orderOut(nil)
      }
      windows.forEach { $0.orderOut(nil) }

      var gridCoverage = "SKIP: nine-window grid requires 1010×770 visible points"
      if visible.width >= 1010, visible.height >= 770 {
        let width = min(350, (visible.width - 80) / 3)
        let height = min(245, (visible.height - 140) / 3)
        let names = ["Top left", "Top center", "Top right", "Left", "Center", "Right",
                     "Bottom left", "Bottom center", "Bottom right"]
        let grid = names.enumerated().map { index, title in
          window("Grid \(title)",
                 x: visible.minX + 10 + CGFloat(index % 3) * (visible.width - width - 20) / 2,
                 y: visible.maxY - height - 32 - CGFloat(index / 3) * (visible.height - height - 42) / 2,
                 width: width, height: height)
        }
        let clockwise = [("right", 1), ("right", 2), ("down", 5), ("down", 8),
                         ("left", 7), ("left", 6), ("up", 3), ("right", 4)]
        let spokes = [("left", 3), ("right", 4), ("up", 1), ("down", 4),
                      ("right", 5), ("left", 4), ("down", 7), ("up", 4)]
        for (label, start, path) in [("clockwise", 0, clockwise), ("center spokes", 4, spokes)] {
          try await prepare(grid[start])
          var from = start
          for (direction, destination) in path {
            try await expectKeyWindow(grid[destination], service: service, pid: pid,
                                      scenario: "grid \(label): \(names[from]) → \(names[destination])",
                                      command: command(direction))
            from = destination
          }
        }
        grid.forEach { $0.orderOut(nil) }
        gridCoverage = "Grid: clockwise and center spokes passed (16 verified hops)"
      }

      return "PASS: center, repeated top-left, and rightward focus from both left anchors to top/middle/bottom\n\(gridCoverage)"
    } catch {
      return "FAIL: \(error); check Accessibility and SpatialFocusSmoke logs"
    }
  }

  private final class KeyTrace: NSObject, NSWindowDelegate {
    var windows: [Int] = []

    func windowDidBecomeKey(_ notification: Notification) {
      if let window = notification.object as? NSWindow { windows.append(window.windowNumber) }
    }
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
    try await launchService(service, command: command ?? ["--smoke-next-window", String(pid)])
    try await Task.sleep(for: .milliseconds(150))
    guard NSApp.isActive, window.isKeyWindow else {
      throw Failure.unexpectedFocus(scenario: scenario, expected: window.title)
    }
  }

  private static func launchService(_ service: String, command: [String]) async throws {
    let status = try await Task.detached {
      // Wait for the one-shot launch without blocking the fixture's AX run loop.
      let process = Process()
      process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
      process.arguments = ["-g", "-n", "-W", service, "--args"] + command
      try process.run()
      process.waitUntilExit()
      return process.terminationStatus
    }
    .value
    guard status == 0 else { throw Failure.launchFailed(status) }

  }
}
