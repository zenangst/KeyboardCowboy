/// The feature-level execution request. Persistence and command metadata belong to the host.
public struct ScriptRequest: Sendable {
  public enum Kind: Sendable {
    case appleScript(Variant)
    case shellScript
  }

  public enum Variant: Sendable {
    case regular, jxa
  }

  public enum Source: Sendable {
    case inline(String), path(String)
  }

  public let id: String
  public let kind: Kind
  public let source: Source

  public init(id: String, kind: Kind, source: Source) {
    self.id = id
    self.kind = kind
    self.source = source
  }
}
