import Foundation

struct WindowTidyCommand: Identifiable, Hashable, Codable, Sendable {
  let id: String
  var rules: [Rule]

  struct Rule: Hashable, Codable, Sendable {
    let bundleIdentifier: String
    let tiling: WindowTiling
  }

  init(id: String = UUID().uuidString, rules: [Rule]) {
    self.id = id
    self.rules = rules
  }

  func copy() -> WindowTidyCommand {
    WindowTidyCommand(id: UUID().uuidString, rules: rules)
  }
}
