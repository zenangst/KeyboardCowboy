import Cocoa

final class OpenFolderInFinder {
  private let finderBundleIdentifier = "com.apple.finder"
  private let engine: ScriptEngine
  private let workspace: WorkspaceProviding

  init(engine: ScriptEngine, workspace: WorkspaceProviding) {
    self.engine = engine
    self.workspace = workspace
  }

  func validate(_ command: OpenCommand) -> Bool {
    command.application?.bundleIdentifier.lowercased() == finderBundleIdentifier ||
    workspace.frontApplication?.bundleIdentifier?.lowercased() == finderBundleIdentifier
  }

  func execute(_ command: OpenCommand) async throws {
    let url = OpenURLParser().parse(command.path)
    let source = """
      tell application "Finder"
        set the target of the front Finder window to folder ("\(url.path)" as POSIX file)
      end tell
      """
    let script = ScriptCommand(name: "Open folder in Finder: \(command.path)",
                               kind: .appleScript,
                               source: .inline(source),
                               notification: false)
    try Task.checkCancellation()
    _ = try await engine.run(script)
  }
}
