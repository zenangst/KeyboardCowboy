import Foundation

struct KeyboardShortcutTrigger: Hashable, Codable, Equatable {
  var passthrough: Bool
  var allowRepeat: Bool = true
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
      holdDuration: holdDuration,
      shortcuts: shortcuts.map { $0.copy() })
  }

  init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.passthrough = try container.decodeIfPresent(Bool.self, forKey: .passthrough) ?? false
    self.allowRepeat = try container.decodeIfPresent(Bool.self, forKey: .allowRepeat) ?? true
    self.holdDuration = try container.decodeIfPresent(Double.self, forKey: .holdDuration)
    self.shortcuts = try container.decode([KeyShortcut].self, forKey: .shortcuts)
  }

  enum CodingKeys: CodingKey {
    case passthrough
    case allowRepeat
    case holdDuration
    case shortcuts
  }

  func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    if passthrough {
      try container.encode(self.passthrough, forKey: .passthrough)
    }

    if allowRepeat == false {
      try container.encode(self.allowRepeat, forKey: .allowRepeat)
    }

    try container.encodeIfPresent(self.holdDuration, forKey: .holdDuration)
    try container.encode(self.shortcuts, forKey: .shortcuts)
  }
}
