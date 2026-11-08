import AppKit

/// Pasteboard operations for `TextInstant`. Workflow-level restoration is owned by the host.
@MainActor
public struct TextPasteboard {
  private let pasteboard: NSPasteboard

  public init(_ pasteboard: NSPasteboard = .general) {
    self.pasteboard = pasteboard
  }

  public func clear() {
    pasteboard.clearContents()
  }

  /// Matches the legacy runner by ignoring the pasteboard write result.
  public func write(_ text: String) {
    pasteboard.setString(text, forType: .string)
  }
}
