import Foundation

struct KeyboardShortcutTrigger: Hashable, Codable, Equatable {
  var passthrough: Bool
  // This is only applicable for singular shortcuts
  var holdDuration: Double?
  let shortcuts: [KeyShortcut]

  init(passthrough: Bool = false, 
       holdDuration: Double? = nil,
       shortcuts: [KeyShortcut]) {
    self.passthrough = passthrough
    self.holdDuration = holdDuration
    self.shortcuts = shortcuts
  }

  func copy() -> Self {
    KeyboardShortcutTrigger(
      passthrough: passthrough,
      shortcuts: shortcuts.map { $0.copy() })
  }
}
