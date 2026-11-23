import AccessibilitySystem

public extension UserSpace {
  /// Reads only when requested. The host supplies clipboard copying and restoration.
  @MainActor
  static func selectedText(
    using accessibility: AccessibilitySystem.Client = .init(),
    fromClipboard: @MainActor () async throws -> String,
  ) async throws -> String {
    let selection: String?
    do {
      selection = try await accessibility.withFocusedElement { focused in
        if let text = try? focused.read(.selectedText) { return text }
        return textWithoutSelection(role: try? focused.read(.role))
      }
    } catch is CancellationError {
      throw CancellationError()
    } catch {
      selection = nil
    }
    if let selection { return selection }
    try Task.checkCancellation()
    return try await fromClipboard()
  }

  // Nil signals that the caller should try copying the selection.
  internal nonisolated static func textWithoutSelection(role: AccessibilitySystem.Role?) -> String? {
    role == .webArea || role == .group ? nil : ""
  }
}
