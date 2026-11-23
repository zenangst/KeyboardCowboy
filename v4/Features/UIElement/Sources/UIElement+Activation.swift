import AccessibilitySystem
import AppKit
import ApplicationServices

public extension UIElement {
  /// Activates the first matching element in the focused window. Returns false
  /// for no frontmost app, no focused window, or no match. Action errors throw.
  @MainActor
  static func activate(
    predicates: [Predicate],
    using accessibility: AccessibilitySystem.Client = .init(),
    budget: AccessibilitySystem.TraversalBudget = .init(),
  ) async throws -> Bool {
    guard !predicates.isEmpty,
          let pid = NSWorkspace.shared.frontmostApplication?.processIdentifier else { return false }

    let pointer = CGEvent(source: nil)?.location
    let activation = try await accessibility.withApplication(processIdentifier: pid) { session -> Activation in
      guard let target = try firstMatch(inFrontmostApplication: session, predicates: predicates, budget: budget) else {
        return .noMatch
      }

      let role = try session.read(.role, of: target)
      if usesPointerClick(role: role, pointer: pointer) {
        return .click(try session.read(.position, of: target))
      }
      try session.perform(.press, on: target)
      return .pressed
    }
    switch activation {
    case .noMatch: return false
    case .pressed: return true
    case .click(let point):
      guard let pointer else { return false }

      try await clickAndRestore(at: point, original: pointer,
                                click: click, restore: restorePointer,
                                wait: { try await Task.sleep(for: .milliseconds(10)) })
      return true
    }
  }

  private enum Activation: Sendable {
    case noMatch, pressed, click(CGPoint)
  }

  enum ActivationError: Error {
    case eventPostingUnavailable, eventCreationFailed
  }

  internal static func usesPointerClick(role: AccessibilitySystem.Role, pointer: CGPoint?) -> Bool {
    pointer != nil && (role == .staticText || role == .cell)
  }

  @MainActor
  internal static func clickAndRestore(
    at point: CGPoint, original: CGPoint,
    click: (CGPoint) throws -> Void, restore: (CGPoint) -> Void,
    wait: () async throws -> Void,
  ) async throws {
    try Task.checkCancellation()
    try click(point)
    defer { restore(original) }
    try await wait()
  }

  private static func click(at point: CGPoint) throws {
    guard CGPreflightPostEventAccess() else { throw ActivationError.eventPostingUnavailable }
    guard let down = mouseEvent(.leftMouseDown, at: point),
          let up = mouseEvent(.leftMouseUp, at: point) else {
      throw ActivationError.eventCreationFailed
    }

    down.setIntegerValueField(.mouseEventClickState, value: 1)
    up.setIntegerValueField(.mouseEventClickState, value: 1)
    down.post(tap: .cghidEventTap)
    up.post(tap: .cghidEventTap)
  }

  private static func restorePointer(to point: CGPoint) {
    mouseEvent(.mouseMoved, at: point)?.post(tap: .cghidEventTap)
  }

  private static func mouseEvent(_ type: CGEventType, at point: CGPoint) -> CGEvent? {
    let event = CGEvent(mouseEventSource: nil, mouseType: type, mouseCursorPosition: point, mouseButton: .left)
    event?.flags = []
    return event
  }
}
