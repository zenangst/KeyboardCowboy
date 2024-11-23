import Cocoa

@MainActor
final class MissionControlPlugin {
  private let keyboard: KeyboardCommandRunner

  nonisolated init(keyboard: KeyboardCommandRunner) {
    self.keyboard = keyboard
  }

  func dismissIfActive() async {
    let windows = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as [AnyObject]? ?? []
    let missionControlIsActive = windows.first { entry in
      guard let appName = entry[kCGWindowOwnerName as String] as? String,
            let layer = entry[kCGWindowLayer as String] as? Int else {
        return false
      }
      return appName == "Dock" && layer == CGWindowLevelKey.desktopIconWindow.rawValue
    } != nil

    if missionControlIsActive {
      _ = try? await keyboard.run([.init(key: "⎋")], originalEvent: nil, iterations: 1, with: nil)
    }
  }
}
