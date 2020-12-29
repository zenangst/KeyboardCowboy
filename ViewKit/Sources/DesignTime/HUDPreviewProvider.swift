import ModelKit

final class HUDPreviewProvider: StateController {
  let state: [KeyboardShortcut] = [
    KeyboardShortcut(key: "A", modifiers: [.command]),
    KeyboardShortcut(key: "D", modifiers: [.command]),
    KeyboardShortcut(key: "C", modifiers: [.function]),
    KeyboardShortcut(key: "D", modifiers: []),
    KeyboardShortcut(key: "=", modifiers: []),
    KeyboardShortcut(key: "Open Terminal", modifiers: [])
  ]
}
