import Foundation

enum AppCache {
  static var rootDirectory: URL {
    try! FileManager.default.url(for: .cachesDirectory,
                                 in: .userDomainMask,
                                 appropriateFor: nil,
                                 create: true)
    .appendingPathComponent(Bundle.main.bundleIdentifier!)
  }

  static func domain(_ name: String) throws -> URL {
    let url = AppCache
      .rootDirectory
      .appendingPathComponent(name)

    if !FileManager.default.fileExists(atPath: url.path) {
      try FileManager.default.createDirectory(
        at: url,
        withIntermediateDirectories: true,
        attributes: nil)
    }

    return url
  }
}
