import Foundation
import Windows

enum SystemWindowRelativeFocusLeft {
  static func findNextWindow(_ currentWindow: WindowModel, windows: [WindowModel]) -> WindowModel? {
    let sortedWindows = windows.systemWindows
      .sorted(by: { $0.index < $1.index })
      .sorted(by: { $0.window.rect.origin.x > $1.window.rect.origin.x })

    let intersectingWindows = sortedWindows.filter { systemWindow in
      let currentMinY = currentWindow.rect.origin.y
      let currentMaxY = currentWindow.rect.origin.y + currentWindow.rect.size.height
      let windowMinY = systemWindow.window.rect.origin.y
      let windowMaxY = systemWindow.window.rect.origin.y + systemWindow.window.rect.size.height
      return windowMinY < currentMaxY && windowMaxY > currentMinY
    }

    for systemWindow in intersectingWindows {
      if systemWindow.window.rect.origin.x < currentWindow.rect.origin.x {
        return systemWindow.window
      }
    }

    for systemWindow in sortedWindows {
      if systemWindow.window.rect.origin.x < currentWindow.rect.origin.x {
        return systemWindow.window
      }
    }

    return currentWindow
  }
}

extension Array<WindowModel> {
  var systemWindows: [SystemWindowModel] { enumerated().reduce(into: [], { result, entry in
    result.append(SystemWindowModel(window: entry.element, index: entry.offset))
  })
  }
}
