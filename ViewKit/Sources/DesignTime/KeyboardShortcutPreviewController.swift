import ModelKit

final class KeyboardShortcutPreviewController: ViewController {
  let state: [ModelKit.KeyboardShortcut] = ModelFactory().keyboardShortcuts()
  func perform(_ action: KeyboardShortcutListView.Action) {}
}
