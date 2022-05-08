import Cocoa

struct AppPreferences {
  var hideFromDock: Bool = true
  var hideAppOnLaunch: Bool = true
  var machportIsEnabled = true
  var storageConfiguration: StorageConfiguration

  static func user() -> AppPreferences {
    AppPreferences(
      hideFromDock: true,
      hideAppOnLaunch: true,
      machportIsEnabled: true,
      storageConfiguration: .init(path: "~/", filename: ".keyboard-cowboy.json"))
  }

  static func designTime() -> AppPreferences {
    AppPreferences(
      hideFromDock: false,
      hideAppOnLaunch: false,
      machportIsEnabled: false,
      storageConfiguration: .init(path: "~/Developer/KC",
                                  filename: "dummyData.json"))
  }

  static func performance() -> AppPreferences {
    AppPreferences(
      hideFromDock: false,
      hideAppOnLaunch: false,
      machportIsEnabled: false,
      storageConfiguration: .init(path: "~/Developer/KC",
                                  filename: "performance.json"))

  }
}
