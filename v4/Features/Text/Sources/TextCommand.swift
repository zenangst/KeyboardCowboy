public struct TextCommand: Codable, Sendable, Equatable {
  public enum Kind: Codable, Sendable, Equatable {
    case insertText(TextInsertCommand)
  }

  public var kind: Kind

  public init(kind: Kind) {
    self.kind = kind
  }
}
