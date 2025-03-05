extension KeyboardCommand {
  struct KeyCommand: Codable, Hashable {
    var keyboardShortcuts: [KeyShortcut]
    var iterations: Int

    init(keyboardShortcuts: [KeyShortcut], iterations: Int) {
      self.keyboardShortcuts = keyboardShortcuts
      self.iterations = iterations
    }
  }
}
