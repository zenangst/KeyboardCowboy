import KeyboardFeature
import KeyCodeSystem
import MachPortSystem

public extension HostInput {
  /// Executes with the latest cached layout and the keyboard tap's tagged poster.
  @MainActor
  static func executeShortcuts(
    _ shortcuts: [Keyboard.Shortcut], iterations: Int = 1,
    using poster: MachPortSystem.KeyboardEventPoster?, layouts: KeyboardLayoutSession,
  ) throws {
    guard let poster else { throw Keyboard.ExecutionError.posterUnavailable }

    try withShortcutLayout(shortcuts, layouts: layouts) { layout in
      try Keyboard.execute(
        shortcuts,
        iterations: iterations,
        using: poster,
        layout: layout)
    }
  }

  @MainActor
  internal static func withShortcutLayout(
    _ shortcuts: [Keyboard.Shortcut], layouts: KeyboardLayoutSession,
    execute: (KeyCodeSystem.Layout) throws -> Void,
  ) throws {
    guard !shortcuts.isEmpty else { return }
    guard let layout = layouts.layout else { throw KeyCodeSystem.LookupError.layoutUnavailable }

    try execute(layout)
  }
}
