import KeyboardFeature
import MachPortSystem

public extension HostInput {
  /// Decodes one routed event for a caller-owned recording session.
  @MainActor
  static func captureShortcut(
    from event: MachPortSystem.EventSnapshot, layouts: KeyboardLayoutSession,
  ) -> Keyboard.Shortcut? {
    guard let layout = layouts.layout else { return nil }

    return Keyboard.captureShortcut(from: event, layout: layout)
  }
}
