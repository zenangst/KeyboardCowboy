import Foundation

final class OpenCommandEngine {
  struct Plugins {
    let finderFolder: OpenFolderInFinder
    let parser = OpenURLParser()
    let open: OpenFilePlugin
    let swapTab = OpenURLSwapTabsPlugin()
  }

  private let plugins: Plugins

  init(_ workspace: WorkspaceProviding) {
    self.plugins = .init(
      finderFolder: OpenFolderInFinder(workspace: workspace),
      open: OpenFilePlugin(workspace: workspace))
  }

  func run(_ command: OpenCommand) async throws {
    let url = plugins.parser.parse(command.path.sanitizedPath)
    if plugins.finderFolder.validate(command) {
      try plugins.finderFolder.execute(command, url: url)
    } else {
//      try plugins.swapTab.execute(command)

      try await plugins.open.execute(command, url: url) 
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
