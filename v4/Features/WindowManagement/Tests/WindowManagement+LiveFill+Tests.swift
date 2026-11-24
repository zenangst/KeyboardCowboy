import AccessibilitySystem
import AppKit
import ApplicationServices
import Testing
import WindowManagementFeature

@MainActor
@Test(.enabled(if: ProcessInfo.processInfo.environment["KC_FILL_SMOKE_FIXTURE"] != nil))
func liveFillTiming() async throws {
  try #require(AXIsProcessTrusted(), "Grant Accessibility to the runner before using the live probe.")
  let fixturePath = try #require(ProcessInfo.processInfo.environment["KC_FILL_SMOKE_FIXTURE"])
  let screens = NSScreen.screens
  let primary = try #require(screens.first)
  let secondary = ProcessInfo.processInfo.environment["KC_FILL_SMOKE_DISPLAY"] == "secondary"
  let screen = try #require(secondary ? screens.dropFirst().first : primary, "Connect a non-mirrored second display.")
  let key = NSDeviceDescriptionKey("NSScreenNumber")
  let displayID = try #require(screen.deviceDescription[key] as? NSNumber).uint32Value
  let area = screen.visibleFrame.insetBy(dx: 28, dy: 28)
  let target = CGRect(x: area.minX, y: primary.frame.maxY - area.maxY, width: area.width, height: area.height)
  let displayBounds = CGRect(x: screen.frame.minX, y: primary.frame.maxY - screen.frame.maxY,
                             width: screen.frame.width, height: screen.frame.height)
  try #require(target.width > 800 && target.height > 600, "Use a display with room to exercise the size constraint.")
  print("Fill display: \(displayID), AX bounds=\(displayBounds)")

  if !secondary {
    for delay in [0, 25, 50, 100, 200, 500] {
      try await probe(delay: delay, constrained: false, target: target, fixturePath: fixturePath,
                      displayID: displayID, displayBounds: displayBounds)
    }
    try await probe(delay: 500, constrained: true, target: target, fixturePath: fixturePath,
                    displayID: displayID, displayBounds: displayBounds)
  }
  for constrained in [false, true] {
    try await probe(delay: nil, constrained: constrained, target: target, fixturePath: fixturePath,
                    displayID: displayID, displayBounds: displayBounds)
  }
  try await probe(delay: nil, constrained: false, target: target, fixturePath: fixturePath,
                  displayID: displayID, displayBounds: displayBounds, switchFocus: true)
}

@MainActor
private func probe(
  delay: Int?, constrained: Bool, target: CGRect, fixturePath: String, displayID: UInt32, displayBounds: CGRect,
  switchFocus: Bool = false,
) async throws {
  let windowNumberFile = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
  defer { try? FileManager.default.removeItem(at: windowNumberFile) }
  let config = NSWorkspace.OpenConfiguration()
  config.createsNewApplicationInstance = true
  let mode = switchFocus ? "switch-focus" : constrained ? "constrained" : "resizable"
  config.arguments = [mode, windowNumberFile.path, String(displayID)]
  let app = try await NSWorkspace.shared.openApplication(at: URL(fileURLWithPath: fixturePath), configuration: config)
  defer { app.terminate() }
  let pid = app.processIdentifier
  let client = AccessibilitySystem.Client()

  func step(_ action: String) async throws -> CGRect {
    try Task.checkCancellation()
    try #require(NSWorkspace.shared.frontmostApplication?.processIdentifier == pid, "Keep the fixture frontmost.")
    return try await client.withApplication(processIdentifier: pid) { session in
      let window = try #require(try session.focusedWindow())
      try #require(try session.read(.title, of: window) == "Window Management Fill Fixture")
      switch action {
      case "position": try session.write(.position, value: target.origin, to: window)
      case "size": try session.write(.size, value: target.size, to: window)
      default: break
      }
      return try session.frame(of: window)
    }
  }

  try await Task.sleep(for: .milliseconds(500))
  let ids = try String(contentsOf: windowNumberFile, encoding: .utf8).split(separator: " ").compactMap { CGWindowID($0) }
  let windowID = try #require(ids.first)
  try #require(windowID != kCGNullWindowID)
  let before = try await step("read")
  try #require(abs(before.width - 420) <= 1, "Fixture has an unexpected starting width. Check tiling rules.")
  try #require(displayBounds.contains(before), "Fixture did not start on the selected display.")
  if delay == nil, !constrained, !switchFocus {
    try await verifyCenterToggle(pid: pid, windowID: windowID, original: before,
                                 display: .init(bounds: displayBounds, visibleBounds: target.insetBy(dx: -28, dy: -28)),
                                 client: client)
    try await verifyResizeRoundTrip(pid: pid, windowID: windowID, original: try await step("read"), client: client)
    try await verifyDisplayRoundTrip(pid: pid, windowID: windowID, start: displayBounds, size: before.size, client: client)
    try await verifyFillRestore(pid: pid, windowID: windowID, target: target, bounds: displayBounds, client: client)
    let afterTransfer = try await step("read")
    try await verifyEdgeShrink(pid: pid, windowID: windowID, area: target.insetBy(dx: -28, dy: -28),
                               size: afterTransfer.size, client: client)
    try await verifyFillRestore(pid: pid, windowID: windowID, target: target, bounds: displayBounds, client: client, toggle: true)
  }
  let expected = constrained ? CGRect(origin: target.origin, size: CGSize(width: 800, height: 600)) : target
  guard let delay else {
    let replacement = switchFocus ? try #require(ids.dropFirst().first) : nil
    let replacementBefore = replacement.flatMap { compositorFrame(windowID: $0, pid: pid) }
    let start = ContinuousClock.now
    let outcome = try await WindowManagement.fillFocusedWindow(
      in: pid, displays: [.init(bounds: displayBounds, visibleBounds: target)], using: client,
    )
    let elapsed = ContinuousClock.now - start
    try await Task.sleep(for: .milliseconds(500))
    let settled = try #require(compositorFrame(windowID: windowID, pid: pid))
    if let replacement {
      let focused = try await client.withApplication(processIdentifier: pid) { session -> CGWindowID? in
        guard let window = try session.focusedWindow() else { return nil }
        return try session.windowIDCandidate(for: window)
      }
      #expect(NSWorkspace.shared.frontmostApplication?.processIdentifier == pid)
      #expect(focused == replacement)
      #expect(outcome == nil)
      #expect(matchesFrame(settled, CGRect(origin: target.origin, size: before.size)))
      let otherBefore = try #require(replacementBefore)
      let otherAfter = try #require(compositorFrame(windowID: replacement, pid: pid))
      #expect(matchesFrame(otherAfter, otherBefore))
      print("Fill focus switch: original moved without resizing; replacement unchanged")
      return
    }
    let result = try #require(outcome)
    #expect(result.requested == target)
    #expect(matchesFrame(result.observed, expected))
    #expect(matchesFrame(settled, expected))
    print("Fill after \(elapsed)\(constrained ? " constrained" : ""): observed=\(result.observed) CG-settled=\(settled) expected=\(expected)")

    let moved = try #require(try await WindowManagement.moveFocusedWindow(
      in: pid, direction: .bottomTrailing, distance: 14,
      constraint: .visibleArea(displays: [.init(bounds: displayBounds, visibleBounds: target.insetBy(dx: -28, dy: -28))]),
      using: client,
    ))
    let expectedMove = expected.offsetBy(dx: 14, dy: 14)
    #expect(matchesFrame(moved.requested, expectedMove))
    #expect(matchesFrame(moved.observed, expectedMove))
    try await Task.sleep(for: .milliseconds(500))
    let settledMove = try #require(compositorFrame(windowID: windowID, pid: pid))
    #expect(matchesFrame(settledMove, expectedMove))
    print("Directional Move: CG-settled=\(settledMove) expected=\(expectedMove)")
    if !constrained {
      let anchor = try #require(try await WindowManagement.anchorFocusedWindow(
        in: pid, direction: .bottomTrailing,
        displays: [.init(bounds: displayBounds, visibleBounds: target.insetBy(dx: -28, dy: -28))],
        padding: 28, using: client,
      ))
      let width = (target.width * 2 / 3).rounded()
      let height = (target.height * 2 / 3).rounded()
      let expectedAnchor = CGRect(x: target.maxX - width, y: target.maxY - height, width: width, height: height)
      try await Task.sleep(for: .milliseconds(500))
      let settledAnchor = try #require(compositorFrame(windowID: windowID, pid: pid))
      print("Anchor: requested=\(anchor.requested) AX=\(anchor.observed) CG-settled=\(settledAnchor) expected=\(expectedAnchor)")
      #expect(matchesFrame(anchor.requested, expectedAnchor))
      #expect(matchesFrame(settledAnchor, expectedAnchor))
    }
    return
  }
  let moved = try await step("position")
  if delay > 0 { try await Task.sleep(for: .milliseconds(delay)) }
  let compositor = compositorFrame(windowID: windowID, pid: pid)
  let resized = try await step("size")
  try await Task.sleep(for: .milliseconds(500))
  let settled = try await step("read")
  let matched = matchesFrame(settled, expected)
  print("Fill \(delay) ms\(constrained ? " constrained" : ""): before=\(before) moved=\(moved) CG-before-resize=\(String(describing: compositor)) resized=\(resized) settled=\(settled) expected=\(expected) matched=\(matched)")
  if delay == 500 { #expect(matched, "The paced control should reach the expected frame.") }
}

@MainActor
private func verifyCenterToggle(
  pid: pid_t, windowID: CGWindowID, original: CGRect, display: WindowManagement.Display, client: AccessibilitySystem.Client,
) async throws {
  let first = try await WindowManagement.toggleFocusedWindowCenter(in: pid, displays: [display], using: client)
  guard case .centered(let frame, let restorePoint)? = first else {
    Issue.record("First Center toggle did not center")
    return
  }
  let point = try #require(restorePoint)
  try await Task.sleep(for: .milliseconds(500))
  let centered = try #require(compositorFrame(windowID: windowID, pid: pid))
  let expected = CGRect(x: display.visibleBounds.midX - original.width / 2, y: display.visibleBounds.midY - original.height / 2,
                        width: original.width, height: original.height)
  #expect(matchesFrame(frame.requested, expected))
  try #require(matchesFrame(centered, expected))
  let second = try await WindowManagement.toggleFocusedWindowCenter(
    in: pid, displays: [display], restoringFrom: point, using: client,
  )
  guard case .restored(let restored)? = second else {
    try #require(Bool(false), "Second Center toggle did not restore: first=\(frame) CG=\(centered) second=\(String(describing: second))")
    return
  }
  try await Task.sleep(for: .milliseconds(500))
  let settled = try #require(compositorFrame(windowID: windowID, pid: pid))
  #expect(restored.requested == original)
  try #require(matchesFrame(settled, original))
  print("Center Toggle: centered=\(centered) restored=\(settled)")
}

@MainActor
private func verifyResizeRoundTrip(
  pid: pid_t, windowID: CGWindowID, original: CGRect, client: AccessibilitySystem.Client,
) async throws {
  let grow = CGRect(x: original.minX - 40, y: original.minY - 40,
                    width: original.width + 40, height: original.height + 40)
  for (change, expected) in [(WindowManagement.ResizeChange.grow, grow), (.shrink, original)] {
    let result = try #require(try await WindowManagement.resizeFocusedWindow(
      in: pid, change: change, direction: .topLeading, distance: 40, using: client,
    ))
    try await Task.sleep(for: .milliseconds(500))
    let settled = try #require(compositorFrame(windowID: windowID, pid: pid))
    #expect(matchesFrame(result.requested, expected))
    try #require(matchesFrame(settled, expected))
    print("Directional Resize \(change): CG-settled=\(settled) expected=\(expected)")
  }
}

@MainActor
private func verifyFillRestore(
  pid: pid_t, windowID: CGWindowID, target: CGRect, bounds: CGRect, client: AccessibilitySystem.Client,
  toggle: Bool = false,
) async throws {
  let displays = [WindowManagement.Display(bounds: bounds, visibleBounds: target)]
  let filled: WindowManagement.FrameResult
  let point: WindowManagement.FillRestorePoint
  if toggle {
    let result = try await WindowManagement.toggleFocusedWindowFill(in: pid, displays: displays, using: client)
    guard case .filled(let frame, let restorePoint)? = result else {
      Issue.record("First Fill toggle did not fill")
      return
    }
    filled = frame
    point = try #require(restorePoint)
  } else {
    let result = try #require(try await WindowManagement.fillFocusedWindowRecordingRestore(in: pid, displays: displays, using: client))
    filled = result.frame
    point = try #require(result.restorePoint)
  }
  try await Task.sleep(for: .milliseconds(500))
  let settledFill = try #require(compositorFrame(windowID: windowID, pid: pid))
  try #require(matchesFrame(settledFill, target))
  let restored: WindowManagement.FrameResult
  if toggle {
    let result = try await WindowManagement.toggleFocusedWindowFill(in: pid, displays: displays, restoringFrom: point, using: client)
    guard case .restored(let frame)? = result else {
      Issue.record("Second Fill toggle did not restore")
      return
    }
    restored = frame
  } else {
    restored = try #require(try await WindowManagement.restoreFocusedWindow(from: point, displays: displays, using: client))
  }
  try await Task.sleep(for: .milliseconds(500))
  let settledRestore = try #require(compositorFrame(windowID: windowID, pid: pid))
  print("Fill Restore: filled=\(settledFill) requested=\(restored.requested) AX=\(restored.observed) CG=\(settledRestore)")
  #expect(restored.requested == filled.original)
  try #require(matchesFrame(settledRestore, filled.original))
  let reused = try await WindowManagement.restoreFocusedWindow(from: point, displays: displays, using: client)
  #expect(reused == nil)
}

@MainActor
private func verifyEdgeShrink(
  pid: pid_t, windowID: CGWindowID, area: CGRect, size: CGSize, client: AccessibilitySystem.Client,
) async throws {
  let start = CGRect(x: area.maxX - size.width, y: area.maxY - size.height, width: size.width, height: size.height)
  try #require(NSWorkspace.shared.frontmostApplication?.processIdentifier == pid, "Keep the fixture frontmost.")
  try await client.withApplication(processIdentifier: pid) { session in
    let window = try #require(try session.focusedWindow())
    let focusedID = try session.windowIDCandidate(for: window)
    try #require(focusedID == windowID)
    try session.write(.position, value: start.origin, to: window)
  }
  try await Task.sleep(for: .milliseconds(500))
  try #require(compositorFrame(windowID: windowID, pid: pid).map { matchesFrame($0, start) } == true)

  let edge = try #require(try await WindowManagement.resizeFocusedWindow(
    in: pid, change: .shrink, direction: .topLeading, distance: 40, using: client,
  ))
  let smaller = CGRect(x: start.minX + 40, y: start.minY + 40, width: size.width - 40, height: size.height - 40)
  try await Task.sleep(for: .milliseconds(500))
  let settledEdge = try #require(compositorFrame(windowID: windowID, pid: pid))
  #expect(matchesFrame(edge.requested, smaller))
  print("Edge Shrink: CG-settled=\(settledEdge) expected=\(smaller)")
  try #require(matchesFrame(settledEdge, smaller))

  let clamped = try #require(try await WindowManagement.resizeFocusedWindow(
    in: pid, change: .shrink, direction: .bottomTrailing, distance: 200, using: client,
  ))
  let requested = CGRect(origin: settledEdge.origin, size: CGSize(width: settledEdge.width - 200, height: settledEdge.height - 200))
  let minimum = CGRect(origin: settledEdge.origin, size: CGSize(width: 200, height: 150))
  try await Task.sleep(for: .milliseconds(500))
  let settledMinimum = try #require(compositorFrame(windowID: windowID, pid: pid))
  print("Minimum Shrink: requested=\(clamped.requested) AX=\(clamped.observed) CG-settled=\(settledMinimum)")
  #expect(matchesFrame(clamped.requested, requested))
  #expect(matchesFrame(clamped.observed, minimum))
  #expect(matchesFrame(settledMinimum, minimum))
}

@MainActor
private func verifyDisplayRoundTrip(
  pid: pid_t, windowID: CGWindowID, start: CGRect, size: CGSize, client: AccessibilitySystem.Client,
) async throws {
  let screens = NSScreen.screens
  guard screens.count == 2, let primary = screens.first else { return }
  func ax(_ rect: CGRect) -> CGRect {
    CGRect(x: rect.minX, y: primary.frame.maxY - rect.maxY, width: rect.width, height: rect.height)
  }
  let displays = screens.map { WindowManagement.Display(bounds: ax($0.frame), visibleBounds: ax($0.visibleFrame)) }
  let source = try #require(displays.firstIndex { $0.bounds == start })
  for destination in [displays[1 - source], displays[source]] {
    try #require(NSWorkspace.shared.frontmostApplication?.processIdentifier == pid, "Keep the fixture frontmost.")
    let visible = destination.visibleBounds.intersection(destination.bounds)
    let expected = CGRect(x: visible.midX - size.width / 2, y: visible.midY - size.height / 2,
                          width: size.width, height: size.height)
    let result = try #require(try await WindowManagement.moveFocusedWindowToNextDisplay(in: pid, displays: displays, using: client))
    try await Task.sleep(for: .milliseconds(500))
    let settled = try #require(compositorFrame(windowID: windowID, pid: pid))
    #expect(matchesFrame(result.requested, expected))
    try #require(matchesFrame(settled, expected))
    print("Next Display: CG-settled=\(settled) expected=\(expected)")
  }
  for (from, to) in [(source, 1 - source), (1 - source, source)] {
    try #require(NSWorkspace.shared.frontmostApplication?.processIdentifier == pid, "Keep the fixture frontmost.")
    let sourceArea = displays[from].visibleBounds.intersection(displays[from].bounds)
    let destination = displays[to].visibleBounds.intersection(displays[to].bounds)
    let result: WindowManagement.FrameResult
    do {
      result = try #require(try await WindowManagement.moveFocusedWindowToNextDisplay(
        in: pid, displays: displays, mode: .relative, using: client,
      ))
    } catch {
      print("Next Display relative failed: from=\(sourceArea) to=\(destination) CG=\(String(describing: compositorFrame(windowID: windowID, pid: pid)))")
      throw error
    }
    let xScale = destination.width / sourceArea.width
    let yScale = destination.height / sourceArea.height
    let expected = CGRect(x: destination.minX + (result.original.minX - sourceArea.minX) * xScale,
                          y: destination.minY + (result.original.minY - sourceArea.minY) * yScale,
                          width: result.original.width * xScale, height: result.original.height * yScale)
    try await Task.sleep(for: .milliseconds(500))
    let settled = try #require(compositorFrame(windowID: windowID, pid: pid))
    #expect(matchesFrame(result.requested, expected))
    try #require(matchesFrame(settled, expected))
    print("Next Display relative: CG-settled=\(settled) expected=\(expected)")
  }
}

private func matchesFrame(_ actual: CGRect, _ expected: CGRect) -> Bool {
  zip([actual.minX, actual.minY, actual.width, actual.height],
      [expected.minX, expected.minY, expected.width, expected.height]).allSatisfy { abs($0 - $1) <= 1 }
}

// The fixture supplies its actual window number; geometry is not used to identify it.
private func compositorFrame(windowID: CGWindowID, pid: pid_t) -> CGRect? {
  guard let rows = CGWindowListCopyWindowInfo(.optionOnScreenOnly, kCGNullWindowID) as? [[String: Any]] else { return nil }
  let windows = rows.filter {
    ($0[kCGWindowNumber as String] as? CGWindowID) == windowID && ($0[kCGWindowOwnerPID as String] as? pid_t) == pid
  }
  guard windows.count == 1, let bounds = windows[0][kCGWindowBounds as String] as? [String: Any] else { return nil }
  return CGRect(dictionaryRepresentation: bounds as CFDictionary)
}
