import AccessibilitySystem
import MachPortSystem
import TextFeature

public extension HostInput {
  @MainActor
  static func textInstant(using poster: MachPortSystem.KeyboardEventPoster?) -> TextInstant {
    let pasteboard = TextPasteboard()
    return TextInstant(
      insertDirectly: textInsertion(),
      clearPasteboard: { pasteboard.clear() },
      writePasteboard: { pasteboard.write($0) },
      post: textPosting(using: poster),
    )
  }

  /// Attempts direct insertion before Text falls back to paste. A failed write
  /// must not trigger paste: the target may already have applied the edit.
  static func textInsertion(
    using accessibility: AccessibilitySystem.Client = .init(),
  ) -> @MainActor (String) async throws -> Bool {
    { text in
      do {
        return try await accessibility.withFocusedElement { focused in
          guard (try? focused.read(.selectedText)) != nil else { return false }
          try? focused.write(.selectedText, value: text)
          return true
        }
      } catch is CancellationError {
        throw CancellationError()
      } catch {
        return false
      }
    }
  }
}
