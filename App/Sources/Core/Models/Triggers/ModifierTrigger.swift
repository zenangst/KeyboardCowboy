import Foundation

struct ModifierTrigger: Hashable, Equatable, Identifiable, Codable, Sendable {
  let id: String
  let modifier: ModifierKey?
  let manipulator: Manipulator?

  struct Manipulator: Codable, Equatable, Sendable {
    let alone: ModifierKey?
    let heldDown: ModifierKey?
    let timout: TimeInterval?
  }

  func copy() -> Self {
    var clone = self
    clone.id = UUID().uuidString
    clone.modifier = self.modifier
    clone.manipulator = self.manipulator
#warning("Fill this out!")
    return clone
  }
}
