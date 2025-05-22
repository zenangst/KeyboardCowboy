extension WallpaperCommand {
  enum Source: Codable, Hashable {
    case file(path: String)
    case folder(folder: Folder)

    var symbolValue: String {
      switch self {
      case .file: "photo"
      case .folder: "photo.stack.fill"
      }
    }

    var displayValue: String {
      switch self {
      case .file: "File"
      case .folder: "Folder"
      }
    }
  }

  struct Folder: Codable, Hashable {
    let path: String
    let strategy: Strategy
  }

  enum Strategy: Codable, Hashable {
    case random
  }
}
