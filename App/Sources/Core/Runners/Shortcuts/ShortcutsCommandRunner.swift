import Foundation

final class ShortcutsCommandRunner {
  private let commandRunner: ScriptCommandRunner

  internal init(_ commandRunner: ScriptCommandRunner) {
    self.commandRunner = commandRunner
  }

  func run(_ command: ShortcutCommand) async throws {
    let source = """
    shortcuts run "\(command.shortcutIdentifier)"
    """
    let shellScript = ScriptCommand(
      id: "ShortcutCommand.\(command.shortcutIdentifier)",
      name: command.name, kind: .shellScript, source: .inline(source), notification: false)
    _ = try await commandRunner.run(shellScript)
  }
}
