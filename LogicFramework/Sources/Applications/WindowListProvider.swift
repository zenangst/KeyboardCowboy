import Foundation

public protocol WindowListProviding {
  func windowOwners() -> [String]
}

class WindowListProvider: WindowListProviding {
  func windowOwners() -> [String] {
    let info = CGWindowListCopyWindowInfo(.optionOnScreenOnly, kCGNullWindowID) as? [[String: Any]] ?? []
    return info.filter {
      ($0[kCGWindowLayer as String] as? Int ?? 0) >= 0
    }.compactMap({ $0[kCGWindowOwnerName as String] as? String })
  }
}
