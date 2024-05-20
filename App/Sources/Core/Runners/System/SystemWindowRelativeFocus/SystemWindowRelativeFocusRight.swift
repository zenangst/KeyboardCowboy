import Foundation
import Windows

enum SystemWindowRelativeFocusRight {
  static func findNextWindow(_ currentWindow: WindowModel, windows: [WindowModel]) -> WindowModel? {
    let sortedWindows = windows.sorted { $0.rect.origin.x < $1.rect.origin.x }

    let intersectingWindows = sortedWindows.filter { window in
      let currentMinY = currentWindow.rect.origin.y
      let currentMaxY = currentWindow.rect.origin.y + currentWindow.rect.size.height
      let windowMinY = window.rect.origin.y
      let windowMaxY = window.rect.origin.y + window.rect.size.height
      return windowMinY < currentMaxY && windowMaxY > currentMinY
    }

    for window in intersectingWindows {
      if window.rect.origin.x >= currentWindow.rect.origin.x {
        return window
      }
    }

    for window in sortedWindows {
      if window.rect.origin.x >= currentWindow.rect.origin.x {
        return window
      }
    }

    return nil
  }
}
