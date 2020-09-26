import Foundation

/// A workflow is a composition of commands that will
/// be invoked when certain criteras are met, either
/// `Group`-level or that the workflow matches the current
/// keyboard invocation.
public struct Workflow: Codable, Hashable {
  public let id: String
  public let commands: [Command]
  public let keyboardShortcuts: [KeyboardShortcut]
  public let name: String

  public var isRebinding: Bool {
    if commands.count == 1, case .keyboard = commands.first { return true }
    return false
  }

  public init(id: String, commands: [Command] = [], keyboardShortcuts: [KeyboardShortcut] = [], name: String) {
    self.id = id
    self.commands = commands
    self.keyboardShortcuts = keyboardShortcuts
    self.name = name
  }

  enum CodingKeys: String, CodingKey {
    case id
    case commands
    case keyboardShortcuts
    case name
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    self.id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
    self.name = try container.decode(String.self, forKey: .name)
    self.commands = try container.decode([Command].self, forKey: .commands)
    self.keyboardShortcuts = try container.decode([KeyboardShortcut].self, forKey: .keyboardShortcuts)
  }
}
