import Carbon
import Foundation

struct ModifierTrigger: Hashable, Equatable, Identifiable, Codable, Sendable {
  enum Kind: Hashable, Equatable, Codable, Sendable {
    case modifiers([ModifierKey])
    case key(AdditionalKey)
  }

  let id: String
  let key: AdditionalKey
  let manipulator: Manipulator

  struct Manipulator: Hashable, Codable, Equatable, Sendable {
    struct HeldDown: Hashable, Codable, Equatable, Sendable {
      let kind: Kind
      let threshold: TimeInterval

      init(kind: Kind, threshold: TimeInterval = 200) {
        self.kind = kind
        self.threshold = threshold
      }
    }

    struct Alone: Hashable, Codable, Equatable, Sendable {
      let kind: Kind
      let timeout: TimeInterval

      init(kind: Kind, timeout: TimeInterval = 75) {
        self.kind = kind
        self.timeout = timeout
      }
    }

    let alone: Alone
    let heldDown: HeldDown?

    init(alone: Alone, heldDown: HeldDown?) {
      self.alone = alone
      self.heldDown = heldDown
    }
  }

  init(id: String, key: AdditionalKey, manipulator: Manipulator?) {
    self.id = id
    self.key = key
    if let manipulator {
      self.manipulator = manipulator
    } else {
      self.manipulator = Manipulator(alone: Manipulator.Alone(kind: .key(key)), heldDown: nil)
    }
  }

  func copy() -> Self {
    ModifierTrigger(id: UUID().uuidString, key: key, manipulator: manipulator)
  }
}

enum AdditionalKey: Hashable, Equatable, Codable, Sendable {
  case escape
  case tab

  var keyCode: Int64 {
    switch self {
    case .escape: Int64(kVK_Escape)
    case .tab: Int64(kVK_Tab)
    }
  }
}
