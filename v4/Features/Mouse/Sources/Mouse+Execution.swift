import AccessibilitySystem
import CoreGraphics

public extension Mouse {
  /// Resolves the focused target, then posts a click. The caller supplies
  /// workflow context for web selections and application-specific positioning.
  /// Returns false if there is no supported target or the pointer is unavailable.
  @MainActor
  @discardableResult
  static func execute(
    _ kind: ClickKind,
    at anchor: Anchor = .center,
    selectedText: String = "",
    applicationBundleIdentifier: String? = nil,
    using accessibility: AccessibilitySystem.Client = .init(),
  ) async throws -> Bool {
    try await execute(kind, resolve: {
      try await focusedTarget(at: anchor, selectedText: selectedText,
                              applicationBundleIdentifier: applicationBundleIdentifier, using: accessibility)
    }, post: { try await post($0, at: $1) })
  }

  @MainActor
  internal static func execute(
    _ kind: ClickKind,
    resolve: () async throws -> CGPoint?,
    post: (ClickKind, CGPoint) async throws -> Bool,
  ) async throws -> Bool {
    try Task.checkCancellation()
    let point = try await resolve()
    try Task.checkCancellation()
    guard let point else { return false }

    return try await post(kind, point)
  }
}
