import Apps
import Cocoa

final class OpenFolderInFinder {
  private let finderBundleIdentifier = "com.apple.finder"
  private let commandRunner: ScriptCommandRunner
  private let workspace: WorkspaceProviding

  init(_ commandRunner: ScriptCommandRunner, workspace: WorkspaceProviding = NSWorkspace.shared) {
    self.commandRunner = commandRunner
    self.workspace = workspace
  }

  func validate(_ bundleIdentifier: String?) -> Bool {
    bundleIdentifier?.lowercased() == finderBundleIdentifier
  }

  func execute(_ path: String, checkCancellation: Bool) async throws {
    let url = OpenURLParser().parse(path)
    let source = """
      tell application "Finder"
        set the target of the front Finder window to folder ("\(url.path)" as POSIX file)
      end tell
      """
    let script = ScriptCommand(name: "Open folder in Finder: \(path)",
                               kind: .appleScript(variant: .regular),
                               source: .inline(source),
                               notification: nil)

    if checkCancellation { try Task.checkCancellation() }
    
    _ = try await commandRunner.run(script, snapshot: UserSpace.shared.snapshot(resolveUserEnvironment: true),
                                    runtimeDictionary: [:], checkCancellation: checkCancellation)
  }
}
