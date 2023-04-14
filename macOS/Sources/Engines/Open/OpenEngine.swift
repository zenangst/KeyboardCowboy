import Foundation

final class OpenEngine {
  struct Plugins {
    let finderFolder: OpenFolderInFinder
    let parser = OpenURLParser()
    let open: OpenFilePlugin
    let swapTab: OpenURLSwapTabsPlugin
  }

  private let plugins: Plugins
  private let workspace: WorkspaceProviding

  init(_ scriptEngine: ScriptEngine, workspace: WorkspaceProviding) {
    self.plugins = .init(
      finderFolder: OpenFolderInFinder(engine: scriptEngine, workspace: workspace),
      open: OpenFilePlugin(workspace: workspace),
      swapTab: OpenURLSwapTabsPlugin(engine: scriptEngine))
    self.workspace = workspace
  }

  func run(_ command: OpenCommand) async throws {
    do {
      if plugins.finderFolder.validate(command) {
        try await plugins.finderFolder.execute(command)
      } else if command.isUrl {
        try await plugins.swapTab.execute(command)
      } else {
        try await plugins.open.execute(command)
      }
    } catch {
      let url = URL(fileURLWithPath: command.path)
      let isDirectory = (try? url.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false
      // TODO: Check if this is what we want.
      if command.application?.bundleName == "Finder", isDirectory == true {
        try await plugins.finderFolder.execute(command)
      } else {
        try await plugins.open.execute(command)
      }
    }
  }
}

extension String {
  var sanitizedPath: String { _sanitizePath() }

  mutating func sanitizePath() {
    self = _sanitizePath()
  }

  /// Expand the tile character used in the path & replace any escaped spaces
  ///
  /// - Returns: A new string that expanded and has no escaped whitespace
  private func _sanitizePath() -> String {
    var path = (self as NSString).expandingTildeInPath
    path = path.replacingOccurrences(of: "", with: "\\ ")
    return path
  }
}
