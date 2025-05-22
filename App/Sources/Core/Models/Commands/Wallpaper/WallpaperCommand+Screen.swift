extension WallpaperCommand {
  struct Screen: Codable, Hashable {
    let match: Match
  }

  enum Match: Codable, Hashable {
    case active
    case main
    case screenName(_ name: String)
  }
}
