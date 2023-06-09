import Cocoa

final class MissionControlPlugin {
  private let keyboard: KeyboardEngine

  init(keyboard: KeyboardEngine) {
    self.keyboard = keyboard
  }

  func execute() {
    let windows = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as [AnyObject]? ?? []
    let missionControlIsActive = !windows.filter { entry in
      guard let appName = entry[kCGWindowOwnerName as String] as? String,
            let layer = entry[kCGWindowLayer as String] as? Int,
            appName == "Dock" &&
            layer == CGWindowLevelKey.desktopIconWindow.rawValue else {
        return false
      }

      return true
    }.isEmpty

    if missionControlIsActive {
      try? keyboard.run(.init(keyboardShortcut: .init(key: "⎋")), type: .keyDown, originalEvent: nil, with: nil)
    }
  }
}
