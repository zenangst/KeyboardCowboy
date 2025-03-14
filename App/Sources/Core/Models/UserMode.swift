import Foundation

struct UserMode: Identifiable, Codable, Hashable, Sendable {
  var id: String
  var name: String
  var isEnabled: Bool

  var asEnabled: UserMode {
    UserMode(id: id, name: name, isEnabled: true)
  }
}

extension Array<UserMode> {
  func dictionaryKey(_ value: Bool) -> String {
    map { $0.dictionaryKey(value) }.joined()
  }
}

extension UserMode {
  func dictionaryKey(_ value: Bool) -> String {
    return "\(prefix())\(value ? 1 : 0))"
  }

  private func prefix() -> String {
    return "UM:\(id):"
  }
}
