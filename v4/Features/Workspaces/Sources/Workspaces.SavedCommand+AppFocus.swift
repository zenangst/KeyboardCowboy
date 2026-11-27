public extension Workspaces.SavedCommand {
  struct AppFocus: Codable, Hashable, Sendable {
    public let id: String
    public let bundleIdentifier: String
    public let hideOtherApps: Bool
    public let createNewWindow: Bool
    public let tiling: Workspaces.Tiling?

    public init(
      id: String, bundleIdentifier: String, hideOtherApps: Bool,
      createNewWindow: Bool = true, tiling: Workspaces.Tiling? = nil,
    ) {
      self.id = id
      self.bundleIdentifier = bundleIdentifier
      self.hideOtherApps = hideOtherApps
      self.createNewWindow = createNewWindow
      self.tiling = tiling
    }

    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      id = try container.decode(String.self, forKey: .id)
      bundleIdentifier = try container.decode(String.self, forKey: .bundleIdentifier)
      hideOtherApps = try container.decode(Bool.self, forKey: .hideOtherApps)
      createNewWindow = try container.decodeIfPresent(Bool.self, forKey: .createNewWindow) ?? true
      tiling = try container.decodeIfPresent(Workspaces.Tiling.self, forKey: .tiling)
    }

    private enum CodingKeys: String, CodingKey {
      case id, hideOtherApps, createNewWindow, tiling
      case bundleIdentifier = "bundleIdentifer"
    }
  }
}
