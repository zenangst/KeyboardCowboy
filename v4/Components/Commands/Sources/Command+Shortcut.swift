public extension Command {
  /// The persisted payload inside the host's `runShortcut` envelope.
  struct Shortcut: MetaDataProviding {
    public let shortcutIdentifier: String
    public var meta: Metadata

    public init(shortcutIdentifier: String, meta: Metadata = Metadata()) {
      self.shortcutIdentifier = shortcutIdentifier
      self.meta = meta
    }

    public func copy() -> Shortcut {
      Shortcut(shortcutIdentifier: shortcutIdentifier, meta: meta.copy())
    }
  }
}
