import Carbon
import Foundation

struct ModifierTrigger: Hashable, Equatable, Identifiable, Codable, Sendable {
  enum Kind: Hashable, Equatable, Codable, Sendable {
    case modifiers([ModifierKey])
    case key(KeyShortcut)
  }

  let id: String
  let key: KeyShortcut
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
      let threshold: TimeInterval

      init(kind: Kind, timeout: TimeInterval = 75) {
        self.kind = kind
        self.threshold = timeout
      }
    }

    let alone: Alone
    let heldDown: HeldDown?

    init(alone: Alone, heldDown: HeldDown?) {
      self.alone = alone
      self.heldDown = heldDown
    }
  }

  init(id: String, key: KeyShortcut, manipulator: Manipulator?) {
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
