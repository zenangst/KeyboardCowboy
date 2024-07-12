import Foundation
import Windows

enum SystemWindowRelativeFocusLeft {
  static func findNextWindow(_ currentWindow: WindowModel, windows: [WindowModel]) -> WindowModel? {
    let sortedWindows = windows.systemWindows.sorted {
      $0.index < $1.index &&
      $0.window.rect.origin.x > $1.window.rect.origin.x
    }

    let intersectingWindows = sortedWindows.filter { model in
      let currentMinY = currentWindow.rect.origin.y
      let currentMaxY = currentWindow.rect.origin.y + currentWindow.rect.size.height
      let windowMinY = model.window.rect.origin.y
      let windowMaxY = model.window.rect.origin.y + model.window.rect.size.height
      return windowMinY < currentMaxY && windowMaxY > currentMinY
    }

    for systemWindow in intersectingWindows {
      if systemWindow.window.rect.origin.x <= currentWindow.rect.origin.x {
        return systemWindow.window
      }
    }

    for systemWindow in sortedWindows {
      if systemWindow.window.rect.origin.x <= currentWindow.rect.origin.x {
        return systemWindow.window
      }
    }

    return currentWindow
  }
}

struct SystemWindowModel: Hashable, Sendable {
  let window: WindowModel
  let index: Int
}

extension Array<WindowModel> {
  var systemWindows: [SystemWindowModel] { enumerated().reduce(into: [], { result, entry in
    result.append(SystemWindowModel(window: entry.element, index: entry.offset))
  })
  }
}
