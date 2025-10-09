import Foundation

enum AppCache {
  static var rootDirectory: URL {
    try! FileManager.default
      .url(for: .cachesDirectory,
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
        attributes: nil,
      )
    }

    return url
  }

  static func load<T: Decodable>(_ domain: String, name: String, decoder: JSONDecoder = .init()) throws -> T? {
    let url = AppCache
      .rootDirectory
      .appendingPathComponent(domain)
      .appending(path: name)

    guard FileManager.default.fileExists(atPath: url.path()) else {
      return nil
    }

    let data = try Data(contentsOf: url)
    return try decoder.decode(T.self, from: data)
  }

  static func entry(_ domain: String, name: String) -> Entry {
    let url = AppCache
      .rootDirectory
      .appendingPathComponent(domain)
      .appending(path: name)
    return Entry(url: url)
  }

  struct Entry {
    let url: URL
    func write(_ object: some Encodable) throws {
      let encoder = JSONEncoder()
      let data = try encoder.encode(object)
      try data.write(to: url)
    }
  }
}
