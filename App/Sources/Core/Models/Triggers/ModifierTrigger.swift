import Carbon
import Foundation

struct ModifierTrigger: Hashable, Equatable, Identifiable, Codable, Sendable {
  enum Kind: Hashable, Equatable, Codable, Sendable {
    case modifiers([ModifierKey])
    case key(AdditionalKey)
  }

  let id: String
  let kind: Kind
  let manipulator: Manipulator?

  struct Manipulator: Hashable, Codable, Equatable, Sendable {
    let alone: Kind?
    let heldDown: Kind?
    let timeout: TimeInterval

    init(alone: Kind?, heldDown: Kind?, timeout: TimeInterval = 100) {
      self.alone = alone
      self.heldDown = heldDown
      self.timeout = timeout
    }
  }

  func copy() -> Self {
    ModifierTrigger(id: UUID().uuidString, kind: kind, manipulator: manipulator)
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
