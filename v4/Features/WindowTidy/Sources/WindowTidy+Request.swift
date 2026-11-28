public extension WindowTidy {
  /// The payload stored under the v3 bundled `tidy.command` key.
  struct Request: Codable, Hashable, Sendable {
    public let id: String
    public let rules: [Rule]

    public init(id: String, rules: [Rule] = []) {
      self.id = id
      self.rules = rules
    }
  }
}
