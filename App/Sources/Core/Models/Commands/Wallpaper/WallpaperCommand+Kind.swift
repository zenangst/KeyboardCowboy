extension WallpaperCommand {
  enum Source: Codable, Hashable {
    case file(path: String)
    case folder(folder: Folder)
  }

  struct Folder: Codable, Hashable {
    let path: String
    let strategy: Strategy
  }

  enum Strategy: Codable, Hashable {
    case random
  }
}
