extension ScriptCommand {
  enum Source: Hashable, Codable, Sendable, Equatable {
    case path(String)
    case inline(String)

    var contents: String {
      get {
        switch self {
        case .path(let contents): contents
        case .inline(let contents): contents
        }
      }
      set {
        switch self {
        case .path(let string):
          self = .path(string)
        case .inline(let string):
          self = .inline(string)
        }
      }
    }
  }
}
