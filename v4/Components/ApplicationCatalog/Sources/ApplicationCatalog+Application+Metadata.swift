public extension ApplicationCatalog.Application {
  struct Metadata: Codable, Hashable, Sendable {
    public var isAgent = false
    public var isElectron = false
    public var isSafariWebApp = false
  }
}
