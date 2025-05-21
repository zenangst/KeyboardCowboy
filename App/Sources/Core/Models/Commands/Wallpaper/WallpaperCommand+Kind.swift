extension WallpaperCommand {
  enum Kind: Codable, Hashable {
    case file(path: String)
    case folder(source: Source)
  }

  struct Source: Codable, Hashable {
    let path: String
    let strategy: Strategy
  }

  enum Strategy: Codable, Hashable {
    case random
    case matchingScreen
  }
}
