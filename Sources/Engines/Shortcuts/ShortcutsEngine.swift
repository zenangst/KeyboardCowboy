import Foundation

final class ShortcutsEngine {
  let script: ScriptEngine

  internal init(script: ScriptEngine) {
    self.script = script
  }

  func run(_ command: ShortcutCommand) async throws {
    let source = """
    shortcuts run "\(command.shortcutIdentifier)"
    """
    let command = ScriptCommand.shell(
      id: "ShortcutCommand.\(command.shortcutIdentifier)",
      isEnabled: true, name: command.name,
      source: .inline(source))
    _ = try await script.run(command)
  }
}
