import Foundation

final class ShortcutsEngine {
  private let engine: ScriptEngine

  internal init(engine: ScriptEngine) {
    self.engine = engine
  }

  func run(_ command: ShortcutCommand) async throws {
    let source = """
    shortcuts run "\(command.shortcutIdentifier)"
    """
    let command = ScriptCommand.shell(
      id: "ShortcutCommand.\(command.shortcutIdentifier)",
      isEnabled: true, name: command.name,
      source: .inline(source))
    _ = try await engine.run(command)
  }
}
