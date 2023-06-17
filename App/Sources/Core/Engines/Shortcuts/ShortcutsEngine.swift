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
    let shellScript = ScriptCommand(
      id: "ShortcutCommand.\(command.shortcutIdentifier)",
      name: command.name, kind: .shellScript, source: .inline(source), notification: false)
    _ = try await engine.run(shellScript)
  }
}
