import Carbon
import Foundation

/// Layout-aware typing using host-provided key lookup and event posting.
@MainActor
public struct TextTyping {
  public struct Modifiers: OptionSet, Sendable {
    public let rawValue: UInt8
    public init(rawValue: UInt8) { self.rawValue = rawValue }
    public static let shift = Self(rawValue: 1 << 0)
    public static let option = Self(rawValue: 1 << 1)
    public static let command = Self(rawValue: 1 << 2)
  }

  public enum KeyEvent: Sendable { case down, up }

  public typealias Lookup = @MainActor (_ text: String, _ modifiers: Modifiers, _ matchDisplay: Bool) -> Int?
  public typealias Post = @MainActor (_ keyCode: Int, _ event: KeyEvent, _ modifiers: Modifiers) throws -> Void

  private struct LookupAttempt {
    let modifiers: Modifiers
    let matchDisplay: Bool
  }

  private static let lookupAttempts: [LookupAttempt] = [
    .init(modifiers: [], matchDisplay: true),
    .init(modifiers: .shift, matchDisplay: true),
    .init(modifiers: .option, matchDisplay: true),
    .init(modifiers: [.option, .shift], matchDisplay: true),
    .init(modifiers: [], matchDisplay: false),
  ]

  private let lookup: Lookup
  private let post: Post
  private let observeText: @MainActor (String) -> Void
  private let observeReturn: @MainActor () -> Void
  private let sleep: @MainActor (Duration) async throws -> Void

  public init(
    lookup: @escaping Lookup,
    post: @escaping Post,
    observeText: @escaping @MainActor (String) -> Void = { _ in },
    observeReturn: @escaping @MainActor () -> Void = {},
    sleep: @escaping @MainActor (Duration) async throws -> Void = { try await Task.sleep(for: $0) },
  ) {
    self.lookup = lookup
    self.post = post
    self.observeText = observeText
    self.observeReturn = observeReturn
    self.sleep = sleep
  }

  /// Intended as the typing handler passed to `TextExecutor`.
  public func run(_ execution: TextExecution) async throws {
    guard !execution.input.isEmpty else { return }

    for character in execution.input {
      let text = String(character)
      observeText(text)
      var resolved: (Int, Modifiers)?
      if CharacterSet(charactersIn: text).isSubset(of: .newlines) {
        resolved = (kVK_Return, [])
      } else {
        for attempt in Self.lookupAttempts {
          if let code = lookup(text, attempt.modifiers, attempt.matchDisplay) {
            resolved = (code, attempt.modifiers)
            break
          }
        }
      }
      if let (code, modifiers) = resolved {
        try post(code, .down, modifiers)
        try post(code, .up, modifiers)
      }
    }

    if execution.actions.contains(.insertEnter) {
      observeReturn()
      try await sleep(.milliseconds(50))
      try post(kVK_Return, .down, [])
      try post(kVK_Return, .up, [])
    }
  }
}
