import Foundation

struct KeyboardShortcutTrigger: Hashable, Codable, Equatable {
  var passthrough: Bool
  var allowRepeat: Bool = true
  var leaderKey: Bool = false
  var keepLastPartialMatch: Bool = false
  var holdDuration: Double?

  let shortcuts: [KeyShortcut]

  init(allowRepeat: Bool = true,
       keepLastPartialMatch: Bool = false,
       leaderKey: Bool = false,
       passthrough: Bool = false,
       holdDuration: Double? = nil,
       shortcuts: [KeyShortcut]) {
    self.allowRepeat = allowRepeat
    self.holdDuration = holdDuration
    self.keepLastPartialMatch = keepLastPartialMatch
    self.leaderKey = leaderKey
    self.passthrough = passthrough
    self.shortcuts = shortcuts
  }

  func copy() -> Self {
    KeyboardShortcutTrigger(
      allowRepeat: allowRepeat,
      keepLastPartialMatch: keepLastPartialMatch,
      leaderKey: leaderKey,
      passthrough: passthrough,
      holdDuration: holdDuration,
      shortcuts: shortcuts.map { $0.copy() })
  }

  init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.passthrough = try container.decodeIfPresent(Bool.self, forKey: .passthrough) ?? false
    self.allowRepeat = try container.decodeIfPresent(Bool.self, forKey: .allowRepeat) ?? true
    self.keepLastPartialMatch = try container.decodeIfPresent(Bool.self, forKey: .keepLastPartialMatch) ?? false
    self.holdDuration = try container.decodeIfPresent(Double.self, forKey: .holdDuration)
    self.shortcuts = try container.decode([KeyShortcut].self, forKey: .shortcuts)
    self.leaderKey = try container.decodeIfPresent(Bool.self, forKey: .leaderKey) ?? false
  }

  enum CodingKeys: CodingKey {
    case passthrough
    case allowRepeat
    case holdDuration
    case shortcuts
    case keepLastPartialMatch
    case leaderKey
  }

  func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    if passthrough {
      try container.encode(self.passthrough, forKey: .passthrough)
    }

    if allowRepeat == false {
      try container.encode(self.allowRepeat, forKey: .allowRepeat)
    }

    if keepLastPartialMatch == true {
      try container.encode(self.keepLastPartialMatch, forKey: .keepLastPartialMatch)
    }

    if leaderKey == true {
      try container.encode(self.leaderKey, forKey: .leaderKey)
    }

    try container.encodeIfPresent(self.holdDuration, forKey: .holdDuration)
    try container.encode(self.shortcuts, forKey: .shortcuts)
  }
}
