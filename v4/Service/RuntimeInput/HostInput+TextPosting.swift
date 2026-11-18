import CoreGraphics
import MachPortSystem
import TextFeature

public enum HostInput {
  /// Text historically treats an absent keyboard poster as a no-op.
  @MainActor
  public static func textPosting(using poster: MachPortSystem.KeyboardEventPoster?) -> TextTyping.Post {
    guard let poster else { return { _, _, _ in } }
    return textPosting { code, action, flags in
      try poster.post(keyCode: code, action: action, flags: flags)
    }
  }

  @MainActor
  static func textPosting(
    post: @escaping @MainActor (CGKeyCode, MachPortSystem.KeyboardEventPoster.KeyAction, CGEventFlags) throws -> Void,
  ) -> TextTyping.Post {
    { keyCode, event, modifiers in
      guard let code = CGKeyCode(exactly: keyCode) else { throw PostingError.invalidKeyCode(keyCode) }
      var flags: CGEventFlags = []
      if modifiers.contains(.shift) { flags.insert(.maskShift) }
      if modifiers.contains(.option) { flags.insert(.maskAlternate) }
      if modifiers.contains(.command) { flags.insert(.maskCommand) }
      try post(code, event == .down ? .down : .up, flags)
    }
  }
}
