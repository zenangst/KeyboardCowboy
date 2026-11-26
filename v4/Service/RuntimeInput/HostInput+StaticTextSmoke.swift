#if DEBUG
import AppKit
import ApplicationServices
import MouseFeature
import OSLog
import UIAutomationFeature

package extension HostInput {
  @MainActor
  static func smokeStaticText(arguments: [String]) async {
    let log = Logger(subsystem: "com.zenangst.keyboardcowboy.v4", category: "UIElementSmoke")
    let kind: Mouse.ClickKind?
    switch arguments {
    case []: kind = nil
    case ["--mouse-post", "left"]: kind = .click
    case ["--mouse-post", "right"]: kind = .rightClick
    case ["--mouse-post", "double"]: kind = .doubleClick
    default:
      log.notice("Expected --smoke-static-text [--mouse-post left|right|double]")
      return
    }
    guard AXIsProcessTrusted(), CGPreflightPostEventAccess() else {
      log.notice("Static-text check requires Accessibility and event posting access")
      return
    }

    let fixture = StaticTextFixture()
    fixture.window.makeKeyAndOrderFront(nil)
    NSApp.activate(ignoringOtherApps: true)
    log.notice("Move the pointer outside the fixture and hold it still")
    do {
      try await Task.sleep(for: .seconds(5))
      if fixture.window.isKeyWindow, NSApp.isActive,
         !fixture.window.frame.contains(NSEvent.mouseLocation), fixture.clickCount == 0,
         let before = CGEvent(source: nil)?.location {
        let activated: Bool
        if let kind {
          guard let point = fixture.targetPoint() else {
            log.error("Could not resolve the test fixture's center")
            fixture.window.close()
            return
          }

          activated = try await Mouse.post(kind, at: point)
        } else {
          activated = try await UIAutomation.activate(predicates: [
            .init(role: .staticText, properties: [.identifier], comparison: .equals, value: fixture.identifier),
          ])
        }
        try await Task.sleep(for: .milliseconds(150))
        let restored = CGEvent(source: nil).map {
          hypot($0.location.x - before.x, $0.location.y - before.y) <= 2
        } ?? false
        let expectedType: NSEvent.EventType = kind == .rightClick ? .rightMouseUp : .leftMouseUp
        let expectedClickState = kind == .doubleClick ? 2 : 1
        let matchesKind = fixture.lastClickType == expectedType && fixture.lastClickState == expectedClickState
        let passed = activated && fixture.clickCount == 1 && restored && (kind == nil || matchesKind)
        fixture.status.stringValue = passed ? "Passed: one click, pointer restored." : "Check failed. See the smoke log."
        log.notice("Static-text activated: \(activated, privacy: .public); clicks: \(fixture.clickCount, privacy: .public); pointer restored: \(restored, privacy: .public)")
        if let kind {
          log.notice("Mouse post \(String(describing: kind), privacy: .public): passed=\(passed, privacy: .public); right mouse up=\(fixture.lastClickType == .rightMouseUp, privacy: .public); click state=\(fixture.lastClickState, privacy: .public)")
        }
      } else {
        fixture.status.stringValue = "Skipped: keep this window focused and the pointer outside it."
        log.notice("Static-text check skipped: fixture not focused, pointer inside, or already clicked")
      }
    } catch {
      fixture.status.stringValue = "Activation failed. See the smoke log."
      log.error("Static-text activation failed: \(String(describing: type(of: error)), privacy: .public)")
    }
    for await _ in fixture.closed { break }
  }
}

@MainActor
private final class StaticTextFixture: NSObject, NSWindowDelegate {
  let identifier = UUID().uuidString
  let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 440, height: 160),
                        styleMask: [.titled, .closable], backing: .buffered, defer: false)
  let status = NSTextField(labelWithString: "Move the pointer outside this window within five seconds.")
  private let counter = NSTextField(labelWithString: "Clicks: 0")
  private let target = NSTextField(labelWithString: "Static Text Test Target")
  private let lifetime = AsyncStream<Void>.makeStream()
  var closed: AsyncStream<Void> { lifetime.stream }
  private(set) var clickCount = 0
  private(set) var lastClickType: NSEvent.EventType?
  private(set) var lastClickState = 0

  override init() {
    super.init()
    target.setAccessibilityRole(.staticText)
    target.setAccessibilityIdentifier(identifier)
    target.sizeToFit()
    target.setFrameOrigin(NSPoint(x: 32, y: 92))
    let content = ClickSurface(frame: NSRect(x: 0, y: 0, width: 440, height: 160))
    content.target = target
    content.onClick = { [weak self] event in
      guard let self else { return }

      clickCount += 1
      lastClickType = event.type
      lastClickState = event.clickCount
      counter.stringValue = "Clicks: \(clickCount)"
    }
    counter.frame = NSRect(x: 32, y: 59, width: 360, height: 20)
    status.frame = NSRect(x: 32, y: 27, width: 390, height: 20)
    for view in [target, counter, status] { content.addSubview(view) }
    window.contentView = content
    window.title = "Static Text Click Smoke Test"
    window.isReleasedWhenClosed = false
    window.delegate = self
    window.center()
  }

  func windowWillClose(_ notification: Notification) { lifetime.continuation.finish() }

  func targetPoint() -> CGPoint? {
    guard let primaryScreen = NSScreen.screens.first else { return nil }

    let frame = target.accessibilityFrame()
    guard !frame.isEmpty else { return nil }

    return CGPoint(x: frame.midX, y: primaryScreen.frame.maxY - frame.midY)
  }

  private final class ClickSurface: NSView {
    weak var target: NSView?
    var onClick: ((NSEvent) -> Void)?

    override func hitTest(_ point: NSPoint) -> NSView? {
      if let target, target.frame.insetBy(dx: -4, dy: -4).contains(convert(point, from: superview)) { return self }
      return super.hitTest(point)
    }

    override func mouseDown(with event: NSEvent) {}
    override func rightMouseDown(with event: NSEvent) {}

    override func mouseUp(with event: NSEvent) { recordClick(event) }
    override func rightMouseUp(with event: NSEvent) { recordClick(event) }

    private func recordClick(_ event: NSEvent) {
      guard let target,
            target.frame.insetBy(dx: -4, dy: -4).contains(convert(event.locationInWindow, from: nil)) else { return }

      onClick?(event)
    }
  }
}
#endif
