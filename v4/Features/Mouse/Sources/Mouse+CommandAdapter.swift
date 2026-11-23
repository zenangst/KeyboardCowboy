import AccessibilitySystem
import Commands

public extension Mouse {
  /// The host supplies workflow context and applies command metadata policy.
  @MainActor
  @discardableResult
  static func execute(
    _ command: Command.Mouse,
    selectedText: String = "",
    applicationBundleIdentifier: String? = nil,
    using accessibility: AccessibilitySystem.Client = .init(),
  ) async throws -> Bool {
    let (kind, anchor) = executionTarget(for: command.kind)
    return try await execute(kind, at: anchor, selectedText: selectedText,
                             applicationBundleIdentifier: applicationBundleIdentifier, using: accessibility)
  }

  internal static func executionTarget(for kind: Command.Mouse.Kind) -> (ClickKind, Anchor) {
    switch kind {
    case .click(.focused(let anchor)): (.click, executionAnchor(anchor))
    case .doubleClick(.focused(let anchor)): (.doubleClick, executionAnchor(anchor))
    case .rightClick(.focused(let anchor)): (.rightClick, executionAnchor(anchor))
    }
  }

  private static func executionAnchor(_ anchor: Command.Mouse.Anchor) -> Anchor {
    switch anchor {
    case .topLeading: .topLeading
    case .top: .top
    case .topTrailing: .topTrailing
    case .leading: .leading
    case .center: .center
    case .trailing: .trailing
    case .bottomLeading: .bottomLeading
    case .bottom: .bottom
    case .bottomTrailing: .bottomTrailing
    case .custom(let x, let y): .custom(x: x, y: y)
    }
  }
}
