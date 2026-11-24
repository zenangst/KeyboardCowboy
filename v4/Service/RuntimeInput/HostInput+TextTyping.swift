import KeyCodeSystem
import MachPortSystem
import TextFeature

public extension HostInput {
  /// Uses the latest available in-memory layout at the start of each typing
  /// command. A missing poster remains a no-op.
  @MainActor
  static func textTyping(
    using poster: MachPortSystem.KeyboardEventPoster?, layouts: KeyboardLayoutSession,
  ) -> TextExecutor.Insertion {
    guard let poster else { return { _ in } }

    return textTyping(layouts: layouts, post: textPosting(using: poster)) {
      try poster.postUnicode($0)
    }
  }

  @MainActor
  internal static func textTyping(
    layouts: KeyboardLayoutSession, post: @escaping TextTyping.Post,
    postUnmapped: (@MainActor (String) throws -> Void)? = nil,
  ) -> TextExecutor.Insertion {
    { execution in
      guard !execution.input.isEmpty else { return }
      guard let layout = layouts.layout else { throw KeyCodeSystem.LookupError.layoutUnavailable }

      try await TextTyping(lookup: { text, modifiers, matchDisplay in
        // Option combinations can invoke editor bindings instead of inserting
        // the character reported by the layout (observed with Option+O).
        if postUnmapped != nil, modifiers.contains(.option), !text.utf8.allSatisfy({ $0 < 128 }) {
          return nil
        }
        return layout.keyCode(for: text, modifiers: textFlags(modifiers), matchDisplayValue: matchDisplay)
      }, post: post, postUnmapped: postUnmapped ?? { _ in }).run(execution)
    }
  }
}
