import CoreGraphics
import MachPortSystem

public enum Keyboard {
  public enum ExecutionError: Error, Equatable {
    case posterUnavailable
    case postingNotPermitted
    case unresolvedKey(String)
    case invalidKeyCode(Int)
  }

  /// Looks up an unmodified key by display value in the caller's keyboard layout.
  public typealias KeyLookup = @MainActor (_ displayValue: String) -> Int?

  /// Posts each shortcut as a down/up pair, in input order, at least once.
  /// Use the active tap's poster so the tap ignores its own synthetic events.
  /// Stops at the first error; earlier events are not rolled back. Core Graphics
  /// does not confirm delivery.
  @MainActor
  @discardableResult
  public static func execute(
    _ shortcuts: [Shortcut], iterations: Int = 1,
    using poster: MachPortSystem.KeyboardEventPoster?, lookup: KeyLookup,
  ) throws -> [CGEvent] {
    guard let poster else { throw ExecutionError.posterUnavailable }

    return try execute(shortcuts, iterations: iterations, lookup: lookup, canPost: CGPreflightPostEventAccess) {
      try poster.post(keyCode: $0, action: $1, flags: $2)
    }
  }

  @MainActor
  static func execute(
    _ shortcuts: [Shortcut], iterations: Int, lookup: KeyLookup, canPost: () -> Bool,
    post: (CGKeyCode, MachPortSystem.KeyboardEventPoster.KeyAction, CGEventFlags) throws -> CGEvent,
  ) throws -> [CGEvent] {
    guard !shortcuts.isEmpty else { return [] }
    guard canPost() else { throw ExecutionError.postingNotPermitted }

    var events: [CGEvent] = []
    for _ in 0 ..< max(1, iterations) {
      for shortcut in shortcuts {
        let key = shortcut.key
        guard let resolved = lookup(key.uppercased()) ?? lookup(key) else {
          throw ExecutionError.unresolvedKey(key)
        }
        guard let code = CGKeyCode(exactly: resolved) else {
          throw ExecutionError.invalidKeyCode(resolved)
        }

        let flags = shortcut.eventFlags(for: code)
        events.append(try post(code, .down, flags))
        events.append(try post(code, .up, flags))
      }
    }
    return events
  }
}
