import AXEssibility
import Cocoa
import Foundation

final class OpenCommandRunner {
  struct Plugins {
    let finderFolder: OpenFolderInFinder
    let parser = OpenURLParser()
    let open: OpenFilePlugin
    let swapTab: OpenURLSwapTabsPlugin
  }

  private let plugins: Plugins
  private let workspace: WorkspaceProviding

  init(_ commandRunner: ScriptCommandRunner, workspace: WorkspaceProviding) {
    self.plugins = .init(
      finderFolder: OpenFolderInFinder(commandRunner, workspace: workspace),
      open: OpenFilePlugin(workspace: workspace),
      swapTab: OpenURLSwapTabsPlugin(commandRunner))
    self.workspace = workspace
  }

  func run(_ command: OpenCommand, snapshot: UserSpace.Snapshot) async throws {
    var interpolatedPath = snapshot.replaceSelectedText(command.path)

    if let frontmostApplication = NSWorkspace.shared.frontmostApplication {
      let app = AppAccessibilityElement(frontmostApplication.processIdentifier)
      if let focusedWindow = try? app.focusedWindow(),
         let documentPath = focusedWindow.document {
        let url = URL(filePath: documentPath)

        if let components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
          let directory = (components.path as NSString)
            .deletingLastPathComponent
            .replacingOccurrences(of: "%20", with: " ")
          interpolatedPath = interpolatedPath
            .replacingOccurrences(of: "$DIRECTORY", with: directory)
            .replacingOccurrences(of: "$FILE", with: url.lastPathComponent)
            .replacingOccurrences(of: "$FILENAME", with: (url.lastPathComponent as NSString).deletingPathExtension)
            .replacingOccurrences(of: "$EXTENSION", with: (url.lastPathComponent as NSString).pathExtension)
        }
      }
    }

    do {
      if plugins.finderFolder.validate(command) {
        try await plugins.finderFolder.execute(interpolatedPath)
      } else if command.isUrl {
        try await plugins.swapTab.execute(interpolatedPath, application: command.application)
      } else {
        try await plugins.open.execute(interpolatedPath, application: command.application)
      }
    } catch {
      let url = URL(fileURLWithPath: command.path)
      let isDirectory = (try? url.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false
      // TODO: Check if this is what we want.
      if command.application?.bundleName == "Finder", isDirectory == true {
        try await plugins.finderFolder.execute(interpolatedPath)
      } else {
        try await plugins.open.execute(interpolatedPath, application: command.application)
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
