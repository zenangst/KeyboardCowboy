import Cocoa
import Foundation

enum WallpaperRunnerError: Error {
  case wallpaperNotFound(_ path: String)
  case notMatchesForRandom(_ path: String)
  case failedToGetContentOfDirectory(_ path: String)
  case unableToSetWallpaper(_ path: String)
}

final class WallpaperCommandRunner {
  func run(_ wallpaper: WallpaperCommand) async throws(WallpaperRunnerError) {
    switch wallpaper.source {
    case .file(let path): try handleFile(path, screens: wallpaper.screens)
    case .folder(let source): try handleFolder(source, screens: wallpaper.screens)
    }
  }

  private func handleFile(_ path: String, screens: [WallpaperCommand.Screen]) throws(WallpaperRunnerError) {
    let url = URL(fileURLWithPath: path)
    for screen in screens {
      guard let nsScreen: NSScreen = getMatchingScreen(screen) else { continue }

      do {
        try NSWorkspace.shared.setDesktopImageURL(url, for: nsScreen)
      } catch {
        throw .unableToSetWallpaper(path)
      }
    }
  }

  private func handleFolder(_ folder: WallpaperCommand.Folder, screens: [WallpaperCommand.Screen]) throws(WallpaperRunnerError) {
    for screen in screens {
      guard let nsScreen: NSScreen = getMatchingScreen(screen) else { continue }

      let url: URL = switch folder.strategy {
      case .random: try random(at: URL(fileURLWithPath: folder.path))
      }

      do {
        try NSWorkspace.shared.setDesktopImageURL(url, for: nsScreen)
      } catch {
        throw .unableToSetWallpaper(url.absoluteString)
      }
    }
  }

  private func getMatchingScreen(_ screen: WallpaperCommand.Screen) -> NSScreen? {
    switch screen.match {
    case .active: NSScreen.main
    case .main: NSScreen.mainDisplay
    case .screenName(let string):
      NSScreen.screens.first(where: { $0.localizedName == string })
    }
  }

  private func random(at url: URL) throws(WallpaperRunnerError) -> URL {
    do {
      let fileManager = FileManager.default
      let files = try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
        .filter { url in
          url.lastPathComponent != ".DS_Store" && ((try? url.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile ?? false) != nil)
        }

      if let randomWallpaper = files.randomElement() {
        return randomWallpaper
      } else {
        throw WallpaperRunnerError.notMatchesForRandom(url.absoluteString)
      }
    } catch {
      throw .failedToGetContentOfDirectory(url.absoluteString)
    }
  }
}
