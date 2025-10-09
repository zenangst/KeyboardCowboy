extension ScriptCommand {
  enum Source: Hashable, Codable, Sendable, Equatable {
    case path(String)
    case inline(String)

    var contents: String {
      get {
        switch self {
        case let .path(contents): contents
        case let .inline(contents): contents
        }
      }
      set {
        switch self {
        case let .path(string):
          self = .path(string)
        case let .inline(string):
          self = .inline(string)
        }
      }
    }
  }
}
