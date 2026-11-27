public extension Workspaces {
  struct SavedWorkspace: Codable, Hashable, Sendable {
    public let id: String
    public let applications: [Application]
    public let tiling: Tiling?
    public let hideOtherApps: Bool
    /// Legacy shortcut modifier tokens, kept in saved order.
    public let appToggleModifiers: [String]
    public let defaultForDynamicWorkspace: Bool

    public var workspace: Workspace {
      .init(applications: applications, tiling: tiling, hideOtherApps: hideOtherApps)
    }

    public init(
      id: String, applications: [Application] = [], tiling: Tiling? = nil,
      hideOtherApps: Bool = false, appToggleModifiers: [String] = [], defaultForDynamicWorkspace: Bool = false,
    ) {
      self.id = id
      self.applications = applications
      self.tiling = tiling
      self.hideOtherApps = hideOtherApps
      self.appToggleModifiers = appToggleModifiers
      self.defaultForDynamicWorkspace = defaultForDynamicWorkspace
    }

    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      id = try container.decode(String.self, forKey: .id)
      if let legacy = try? container.decodeIfPresent([String].self, forKey: .bundleIdentifiers) {
        applications = legacy.map { Application($0) }
      } else {
        applications = try container.decodeIfPresent([Application].self, forKey: .applications) ?? []
      }
      tiling = try container.decodeIfPresent(Tiling.self, forKey: .tiling)
      hideOtherApps = try container.decode(Bool.self, forKey: .hideOtherApps)
      appToggleModifiers = try container.decodeIfPresent([String].self, forKey: .appToggleModifiers) ?? []
      defaultForDynamicWorkspace = try container.decodeIfPresent(Bool.self, forKey: .defaultForDynamicWorkspace) ?? false
    }

    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      try container.encode(id, forKey: .id)
      if !applications.isEmpty { try container.encode(applications, forKey: .applications) }
      try container.encodeIfPresent(tiling, forKey: .tiling)
      try container.encode(hideOtherApps, forKey: .hideOtherApps)
      if !appToggleModifiers.isEmpty { try container.encode(appToggleModifiers, forKey: .appToggleModifiers) }
      if defaultForDynamicWorkspace { try container.encode(true, forKey: .defaultForDynamicWorkspace) }
    }

    private enum CodingKeys: CodingKey {
      case id, applications, bundleIdentifiers, tiling, hideOtherApps, appToggleModifiers, defaultForDynamicWorkspace
    }
  }
}
