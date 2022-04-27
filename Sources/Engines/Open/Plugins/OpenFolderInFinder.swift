import Cocoa

final class OpenFolderInFinder {
  enum OpenFolderInFinderError: Error {
    case failedToCreateScript
    case failedToRun
  }
  private let finderBundleIdentifier = "com.apple.finder"
  let workspace: WorkspaceProviding

  init(workspace: WorkspaceProviding) {
    self.workspace = workspace
  }

  func execute(_ command: OpenCommand, url: URL) throws {
    var dictionary: NSDictionary?
    let script = try createAppleScript(url)
    _ = script.executeAndReturnError(&dictionary).booleanValue
    if dictionary != nil {
      throw OpenFolderInFinderError.failedToRun
    }
  }

  func validate(_ command: OpenCommand) -> Bool {
    command.application?.bundleIdentifier.lowercased() == finderBundleIdentifier ||
    workspace.frontApplication?.bundleIdentifier?.lowercased() == finderBundleIdentifier
  }

  // MARK: Private methods

  private func createAppleScript(_ url: URL) throws -> NSAppleScript {
    let source = """
      tell application "Finder"
        set the target of the front Finder window to folder ("\(url.path)" as POSIX file)
      end tell
      """

    guard let script = NSAppleScript(source: source) else {
      throw OpenFolderInFinderError.failedToCreateScript
    }

    return script
  }
}
