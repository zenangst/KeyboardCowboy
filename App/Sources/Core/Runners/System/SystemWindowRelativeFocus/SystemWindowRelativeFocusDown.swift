import Foundation
import Windows

enum SystemWindowRelativeFocusDown {
  static func findNextWindow(_ currentWindow: WindowModel, windows: [WindowModel]) -> WindowModel? {
    let sortedWindows = windows.systemWindows
      .sorted(by: { $0.index < $1.index })
      .sorted(by: { $0.window.rect.origin.y < $1.window.rect.origin.y })

    let intersectingWindows = sortedWindows.filter { systemWindow in
      let currentMinX = currentWindow.rect.origin.x
      let currentMaxX = currentWindow.rect.maxX
      let windowMinX = systemWindow.window.rect.origin.x
      let windowMaxX = systemWindow.window.rect.maxX
      return systemWindow.window.rect.origin.y > currentWindow.rect.origin.y
      && windowMinX <= currentMaxX && windowMaxX >= currentMinX
    }

    for systemWindow in intersectingWindows {
      if systemWindow.window.rect.origin.y > currentWindow.rect.origin.y {
        return systemWindow.window
      }
    }

    for systemWindow in sortedWindows {
      if systemWindow.window.rect.origin.y > currentWindow.rect.origin.y {
        return systemWindow.window
      }
    }

    return currentWindow
  }
}
