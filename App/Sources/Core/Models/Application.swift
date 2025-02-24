import Foundation
import Apps

public extension Application {
  static func empty(id: String = UUID().uuidString) -> Application {
    Application(bundleIdentifier: "", bundleName: "", displayName: "", path: "")
  }

  static func messages(id: String = UUID().uuidString, name: String? = nil) -> Application {
    Application(
      bundleIdentifier: "com.apple.MobileSMS",
      bundleName: name ?? "Messages",
      displayName: name ?? "Messages",
      path: "/System/Applications/Messages.app")
  }

  static func finder(id: String = UUID().uuidString) -> Application {
    Application(
      bundleIdentifier: "com.apple.finder",
      bundleName: "Finder",
      displayName: "Finder",
      path: "/System/Library/CoreServices/Finder.app")
  }

  static func systemSettings(id: String = UUID().uuidString) -> Application {
    Application(
      bundleIdentifier: "com.apple.systempreferences",
      bundleName: "System Settings",
      displayName: "System Settings",
      path: "/System/Applications/System Settings.app")
  }

  static func photoshop(id: String = UUID().uuidString) -> Application {
    Application(
      bundleIdentifier: "com.adobe.Photoshop",
      bundleName: "Photoshop",
      displayName: "Photoshop",
      path: "/Applications/Adobe Photoshop 2020/Adobe Photoshop 2020.app")
  }

  static func sketch(id: String = UUID().uuidString) -> Application {
    Application(
      bundleIdentifier: "com.bohemiancoding.sketch3",
      bundleName: "Sketch",
      displayName: "Sketch",
      path: "/Applications/Sketch.app")
  }

  static func safari(id: String = UUID().uuidString) -> Application {
    Application(
      bundleIdentifier: "com.apple.Safari",
      bundleName: "Safari",
      displayName: "Safari",
      path: "/Applications/Safari.app")
  }

  static func xcode(id: String = UUID().uuidString) -> Application {
    Application(
      bundleIdentifier: "com.apple.dt.Xcode",
      bundleName: "Sketch",
      displayName: "Sketch",
      path: "/Applications/Xcode.app")
  }

  static func music(id: String = UUID().uuidString) -> Application {
    Application(
      bundleIdentifier: "com.apple.Music",
      bundleName: "Music",
      displayName: "Music",
      path: "/System/Applications/Music.app")
  }

  static func calendar(id: String = UUID().uuidString) -> Application {
    Application(
      bundleIdentifier: "com.apple.calendar",
      bundleName: "Calendar",
      displayName: "Calendar",
      path: "/System/Applications/Calendar.app")
  }
}
