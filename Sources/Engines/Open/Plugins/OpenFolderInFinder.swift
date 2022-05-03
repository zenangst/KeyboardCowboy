import Cocoa

final class OpenFolderInFinder {
  private let finderBundleIdentifier = "com.apple.finder"
  let workspace: WorkspaceProviding
  let engine = ScriptCommandEngine()

  init(workspace: WorkspaceProviding) {
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
    let script = ScriptCommand.appleScript(
      id: "OpenFolderInFinder.\(command.path)",
      isEnabled: true,
      name: "Open folder in Finder: \(command.path)",
      source: .inline(source))
    _ = try await engine.run(script)
  }
}
