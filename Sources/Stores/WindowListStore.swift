import Foundation

public protocol WindowListStoring {
  func windowOwners() -> [String]
}

final class WindowListStore: WindowListStoring {
  /// Get a list of owners based on the currently open windows.
  ///
  /// - Returns: A collection of window names, the window names are the bundle
  ///            names of the window owner.
  func windowOwners() -> [String] {
    let options: CGWindowListOption = [
      .optionOnScreenOnly, .excludeDesktopElements
    ]
    let info = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] ?? []
    return info.filter {
      ($0[kCGWindowLayer as String] as? Int ?? 0) >= 0
    }.compactMap({ $0[kCGWindowOwnerName as String] as? String })
  }
}
