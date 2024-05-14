import Foundation
import Windows

enum SystemWindowRelativeFocusUp {
  static func findNextWindow(_ currentWindow: WindowModel, windows: [WindowModel]) -> WindowModel? {
    let sortedWindows = windows.sorted { $0.rect.origin.y > $1.rect.origin.y }

    let intersectingWindows = sortedWindows.filter { window in
      let currentMinX = currentWindow.rect.origin.x
      let currentMaxX = currentWindow.rect.maxX
      let windowMinX = window.rect.origin.x
      let windowMaxX = window.rect.maxX
      return window.rect.origin.y < currentWindow.rect.origin.y
      && windowMinX <= currentMaxX && windowMaxX >= currentMinX
    }

    return intersectingWindows.first
  }
}
