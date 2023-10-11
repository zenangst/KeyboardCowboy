import Cocoa

final class OpenFolderInFinder {
  private let finderBundleIdentifier = "com.apple.finder"
  private let commandRunner: ScriptCommandRunner
  private let workspace: WorkspaceProviding

  init(_ commandRunner: ScriptCommandRunner, workspace: WorkspaceProviding = NSWorkspace.shared) {
    self.commandRunner = commandRunner
    self.workspace = workspace
  }

  func validate(_ command: OpenCommand) -> Bool {
    command.application?.bundleIdentifier.lowercased() == finderBundleIdentifier ||
    workspace.frontApplication?.bundleIdentifier?.lowercased() == finderBundleIdentifier
  }

  func execute(_ path: String) async throws {
    let url = OpenURLParser().parse(path)
    let source = """
      tell application "Finder"
        set the target of the front Finder window to folder ("\(url.path)" as POSIX file)
      end tell
      """
    let script = ScriptCommand(name: "Open folder in Finder: \(path)",
                               kind: .appleScript,
                               source: .inline(source),
                               notification: false)
    try Task.checkCancellation()
    _ = try await commandRunner.run(script)
  }
}
