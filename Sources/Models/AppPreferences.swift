import Cocoa

struct AppPreferences {
  var hideAppOnLaunch: Bool = false
  var storageConfiguration: StorageConfiguration

  static func user() -> AppPreferences {
    AppPreferences(hideAppOnLaunch: true,
                   storageConfiguration: .init(path: "~/", filename: ".keyboard-cowboy.json"))
  }

  static func designTime() -> AppPreferences {
    AppPreferences(
      hideAppOnLaunch: false,
      storageConfiguration: .init(path: "~/Developer/KC",
                                  filename: "dummyData.json"))
  }

  static func performance() -> AppPreferences {
    AppPreferences(
      hideAppOnLaunch: false,
      storageConfiguration: .init(path: "~/Developer/KC",
                                  filename: "performance.json"))

  }
}
