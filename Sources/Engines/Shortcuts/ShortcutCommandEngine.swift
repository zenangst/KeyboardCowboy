import Foundation

final class ShortcutCommandEngine {
  let script: ScriptCommandEngine

  internal init(script: ScriptCommandEngine) {
    self.script = script
  }

  func run(_ shortcutCommand: ShortcutCommand) async throws {
    let source = """
    shortcuts run "\(shortcutCommand.shortcutIdentifier)"
    """
    let command = ScriptCommand.shell(
      id: "ShortcutCommand.\(shortcutCommand.shortcutIdentifier)",
      isEnabled: true, name: shortcutCommand.name,
      source: .inline(source))
    _ = try await script.run(command)
  }
}
