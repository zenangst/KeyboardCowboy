import Carbon

/// Instant insertion with a host-supplied direct insertion attempt and paste fallback.
@MainActor
public struct TextInstant {
  private let insertDirectly: @MainActor (String) -> Bool
  private let clearPasteboard: @MainActor () -> Void
  private let writePasteboard: @MainActor (String) -> Void
  private let post: TextTyping.Post
  private let observeText: @MainActor (String) -> Void
  private let observeReturn: @MainActor () -> Void
  private let sleep: @MainActor (Duration) async throws -> Void

  /// `insertDirectly` returns true if a focused element had a non-nil selection
  /// and the host attempted insertion, even if the underlying write was unsuccessful.
  /// Focus lookup failure and a nil selection must return false.
  public init(
    insertDirectly: @escaping @MainActor (String) -> Bool,
    clearPasteboard: @escaping @MainActor () -> Void,
    writePasteboard: @escaping @MainActor (String) -> Void,
    post: @escaping TextTyping.Post,
    observeText: @escaping @MainActor (String) -> Void = { _ in },
    observeReturn: @escaping @MainActor () -> Void = {},
    sleep: @escaping @MainActor (Duration) async throws -> Void = { try await Task.sleep(for: $0) },
  ) {
    self.insertDirectly = insertDirectly
    self.clearPasteboard = clearPasteboard
    self.writePasteboard = writePasteboard
    self.post = post
    self.observeText = observeText
    self.observeReturn = observeReturn
    self.sleep = sleep
  }

  /// Intended as the instant handler passed to `TextExecutor`.
  public func run(_ execution: TextExecution) async throws {
    guard !execution.input.isEmpty else { return }

    if !insertDirectly(execution.input) {
      clearPasteboard()
      writePasteboard(execution.input)
      observeText(execution.input)
      try await sleep(.milliseconds(100))
      try post(kVK_ANSI_V, .down, .command)
      try post(kVK_ANSI_V, .up, .command)
    }

    if execution.actions.contains(.insertEnter) {
      observeReturn()
      try await sleep(.milliseconds(50))
      try post(kVK_Return, .down, [])
      try post(kVK_Return, .up, [])
    }
  }
}
