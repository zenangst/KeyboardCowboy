import Foundation

struct KeyboardShortcutTrigger: Hashable, Codable, Equatable {
  var passthrough: Bool
  var allowRepeat: Bool = true
  // This is only applicable for singular shortcuts
  var holdDuration: Double?
  let shortcuts: [KeyShortcut]

  init(allowRepeat: Bool = true,
       passthrough: Bool = false,
       holdDuration: Double? = nil,
       shortcuts: [KeyShortcut]) {
    self.allowRepeat = allowRepeat
    self.holdDuration = holdDuration
    self.passthrough = passthrough
    self.shortcuts = shortcuts
  }

  func copy() -> Self {
    KeyboardShortcutTrigger(
      allowRepeat: allowRepeat,
      passthrough: passthrough,
      shortcuts: shortcuts.map { $0.copy() })
  }

  init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.passthrough = try container.decode(Bool.self, forKey: .passthrough)
    self.allowRepeat = try container.decodeIfPresent(Bool.self, forKey: .allowRepeat) ?? true
    self.holdDuration = try container.decodeIfPresent(Double.self, forKey: .holdDuration)
    self.shortcuts = try container.decode([KeyShortcut].self, forKey: .shortcuts)
  }
}
