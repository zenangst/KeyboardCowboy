import Foundation

struct KeyboardShortcutTrigger: Hashable, Codable, Equatable {
  var passthrough: Bool
  let shortcuts: [KeyShortcut]

  init(passthrough: Bool = false, shortcuts: [KeyShortcut]) {
    self.passthrough = passthrough
    self.shortcuts = shortcuts
  }
}
