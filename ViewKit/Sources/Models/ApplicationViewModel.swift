import Foundation

public struct ApplicationViewModel: Hashable, Identifiable, Equatable {
  public let bundleIdentifier: String
  public let id: String
  public let name: String
  public let path: String

  public init(id: String = UUID().uuidString,
              bundleIdentifier: String,
              name: String,
              path: String) {
    self.bundleIdentifier = bundleIdentifier
    self.id = id
    self.name = name
    self.path = path
  }
}

extension ApplicationViewModel {
  static func empty() -> ApplicationViewModel {
    ApplicationViewModel(bundleIdentifier: "", name: "", path: "")
  }

  static func messages() -> ApplicationViewModel {
    ApplicationViewModel(
      bundleIdentifier: "com.apple.MobileSMS",
      name: "Messages",
      path: "/System/Applications/Messages.app")
  }

  static func finder(id: String = UUID().uuidString) -> ApplicationViewModel {
    ApplicationViewModel(
      id: id,
      bundleIdentifier: "com.apple.finder",
      name: "Finder", path: "/System/Library/CoreServices/Finder.app")
  }

  static func photoshop() -> ApplicationViewModel {
    ApplicationViewModel(
      bundleIdentifier: "com.adobe.Photoshop",
      name: "Photoshop",
      path: "/Applications/Adobe Photoshop 2020/Adobe Photoshop 2020.app")
  }

  static func sketch() -> ApplicationViewModel {
    ApplicationViewModel(
      bundleIdentifier: "com.bohemiancoding.sketch3",
      name: "Sketch",
      path: "/Applications/Sketch.app")
  }

  static func xcode() -> ApplicationViewModel {
    ApplicationViewModel(
      bundleIdentifier: "com.apple.dt.Xcode",
      name: "Sketch",
      path: "/Applications/Xcode.app")
  }

  static func music() -> ApplicationViewModel {
    ApplicationViewModel(
      bundleIdentifier: "com.apple.music",
      name: "Music",
      path: "/System/Applications/Music.app")
  }

  static func calendar() -> ApplicationViewModel {
    ApplicationViewModel(
      bundleIdentifier: "com.apple.calendar",
      name: "Calendar",
      path: "/System/Applications/Calendar.app")
  }
}
