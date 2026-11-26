import Foundation

public extension ApplicationCatalog {
  struct Application: Identifiable, Codable, Hashable, Sendable {
    public var id: String { path }
    public let bundleIdentifier: String
    public let bundleName: String
    public let path: String
    public var metadata = Metadata()
    public var displayName: String

    public init(bundleIdentifier: String, bundleName: String, displayName: String? = nil, path: String) {
      self.bundleIdentifier = bundleIdentifier
      self.bundleName = bundleName
      self.displayName = displayName ?? bundleName
      self.path = path
    }

    private enum CodingKeys: String, CodingKey {
      case bundleIdentifier, bundleName, displayName, path, metadata
    }

    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      bundleIdentifier = try container.decode(String.self, forKey: .bundleIdentifier)
      bundleName = try container.decode(String.self, forKey: .bundleName)
      path = try container.decode(String.self, forKey: .path)
      displayName = (try? container.decode(String.self, forKey: .displayName))
        ?? FileManager.default.displayName(atPath: path)
      metadata = (try? container.decode(Metadata.self, forKey: .metadata)) ?? Metadata()
    }

    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      try container.encode(bundleIdentifier, forKey: .bundleIdentifier)
      try container.encode(bundleName, forKey: .bundleName)
      try container.encode(displayName, forKey: .displayName)
      try container.encode(path, forKey: .path)
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
      lhs.bundleIdentifier == rhs.bundleIdentifier && lhs.bundleName == rhs.bundleName && lhs.path == rhs.path
    }

    public func hash(into hasher: inout Hasher) {
      hasher.combine(bundleIdentifier)
      hasher.combine(bundleName)
      hasher.combine(path)
    }
  }
}
