import Foundation

struct ModifierTrigger: Hashable, Equatable, Identifiable, Codable, Sendable {
  var id: String
  var modifier: ModifierKey?
  var manipulator: Manipulator?

  struct Manipulator: Hashable, Codable, Equatable, Sendable {
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
