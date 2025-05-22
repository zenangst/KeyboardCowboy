extension WallpaperCommand {
  struct Screen: Identifiable, Codable, Hashable {
    let id: String
    var match: Match
  }

  enum Match: Codable, Hashable {
    case active
    case main
    case screenName(_ name: String)

    var displayValue: String {
      switch self {
        case .active:
        return "Activate Display"
      case .main:
        return "The Primary Display"
      case .screenName:
        return "Screen matching"
      }
    }
  }
}
