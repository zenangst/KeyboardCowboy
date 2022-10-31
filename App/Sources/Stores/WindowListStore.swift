import CoreGraphics
import Foundation
import Windows

public protocol WindowListStoring {
  func windowOwners() -> [String]
}

final class WindowListStore: WindowListStoring {
  /// Get a list of owners based on the currently open windows.
  ///
  /// - Returns: A collection of window names, the window names are the bundle
  ///            names of the window owner.
  func windowOwners() -> [String] {
    let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
    let info: [WindowModel] = (try? WindowsInfo.getWindows(options)) ?? []
    return info.compactMap({ $0.ownerName })
  }
}
