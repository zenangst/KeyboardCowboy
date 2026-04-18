import Apps
import AXEssibility
import Cocoa
import Foundation

final class OpenCommandRunner: Sendable {
  struct Plugins: Sendable {
    let finderFolder: OpenFolderInFinder
    let parser = OpenURLParser()
    let open: OpenFilePlugin
    let swapTab: OpenURLSwapTabsPlugin
    let webApp: OpenURLSafariWebAppPlugin
  }

  private let plugins: Plugins
  private let workspace: WorkspaceProviding

  init(_ commandRunner: ScriptCommandRunner, workspace: WorkspaceProviding) {
    plugins = .init(
      finderFolder: OpenFolderInFinder(commandRunner, workspace: workspace),
      open: OpenFilePlugin(workspace: workspace),
      swapTab: OpenURLSwapTabsPlugin(commandRunner),
      webApp: OpenURLSafariWebAppPlugin(commandRunner),
    )
    self.workspace = workspace
  }

  func run(_ path: String, checkCancellation: Bool, application: Application?) async throws {
    if resolvesToKeyboardCowboy(path, application: application) {
      await MainActor.run {
        NotificationCenter.default.post(name: .openKeyboardCowboy, object: nil)
      }
      return
    }

    do {
      if plugins.finderFolder.validate(application?.bundleIdentifier) {
        try await plugins.finderFolder.execute(path, checkCancellation: checkCancellation)
      } else if path.isUrl {
        if let application, application.bundleIdentifier.hasPrefix("com.apple.Safari.WebApp") {
          try await plugins.webApp.execute(path, application: application, checkCancellation: checkCancellation)
          return
        } else if let application, application.bundleIdentifier.hasPrefix("com.kagi.kagimacOS.WebApp") {
          try await plugins.webApp.execute(path, application: application, checkCancellation: checkCancellation)
          return
        } else {
          try await plugins.swapTab.execute(path,
                                            appName: application?.displayName ?? "Safari",
                                            appPath: application?.path,
                                            bundleIdentifier: application?.bundleIdentifier,
                                            checkCancellation: checkCancellation)
        }
      } else {
        try await plugins.open.execute(path, application: application)
      }
    } catch {
      let url = URL(fileURLWithPath: path)
      let isDirectory = (try? url.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false
      // TODO: Check if this is what we want.
      if application?.bundleName == "Finder", isDirectory == true {
        try await plugins.finderFolder.execute(path, checkCancellation: checkCancellation)
      } else {
        try await plugins.open.execute(path, application: application)
      }
    }
  }

  private func resolvesToKeyboardCowboy(_ path: String, application: Application?) -> Bool {
    if application?.bundleIdentifier == KeyboardCowboyApp.bundleIdentifier {
      return true
    }

    guard !path.isUrl else { return false }

    let expandedPath = (path as NSString).expandingTildeInPath
    let resolvedPath = URL(fileURLWithPath: expandedPath)
      .standardizedFileURL
      .resolvingSymlinksInPath()
      .path

    let bundlePath = Bundle.main.bundleURL
      .standardizedFileURL
      .resolvingSymlinksInPath()
      .path

    return resolvedPath == bundlePath
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

  var isUrl: Bool {
    if let url = URL(string: self) {
      if url.host == nil || url.isFileURL {
        false
      } else {
        true
      }
    } else {
      false
    }
  }
}
