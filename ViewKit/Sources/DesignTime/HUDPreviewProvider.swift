import ModelKit

final class HUDPreviewProvider: StateController {
  let state: [KeyboardShortcut] = [
    KeyboardShortcut(key: "A", modifiers: [.function]),
    KeyboardShortcut(key: "T", modifiers: []),
    KeyboardShortcut(key: "Open Terminal", modifiers: [])
  ]
}
