import Carbon
import Foundation

struct ModifierTrigger: Hashable, Equatable, Identifiable, Codable, Sendable {
  enum Kind: Hashable, Equatable, Codable, Sendable {
    case modifiers([ModifierKey])
    case key(KeyShortcut)

    var keyCode: Int? {
      switch self {
      case let .modifiers(modifiers): modifiers.keyCode
      case let .key(key): key.keyCode
      }
    }

    var cgModifiers: CGEventFlags {
      switch self {
      case let .modifiers(modifiers): modifiers.cgModifiers
      case .key: [] // No modifiers for a single key
      }
    }
  }

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

    init(kind: Kind, threshold: TimeInterval = 75) {
      self.kind = kind
      self.threshold = threshold
    }
  }

  let id: String
  let alone: Alone
  let heldDown: HeldDown?

  var keyCode: Int? { alone.kind.keyCode }

  init(id: String, alone: Alone, heldDown: HeldDown?) {
    self.id = id
    self.alone = alone
    self.heldDown = heldDown
  }

  func copy() -> Self {
    ModifierTrigger(id: UUID().uuidString, alone: alone, heldDown: heldDown)
  }
}
