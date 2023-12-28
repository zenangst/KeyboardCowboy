import Cocoa

private let rootFolder = URL(fileURLWithPath: #file).pathComponents
  .prefix(while: { $0 != "KeyboardCowboy" })
  .joined(separator: "/")
  .dropFirst()

struct AppPreferences {
  var hideFromDock: Bool = true
  var hideAppOnLaunch: Bool = true
  var machportIsEnabled = true
  var storageConfiguration: any StoringConfiguration

  private static func filename(for functionName: StaticString) -> String {
    "\(functionName)"
      .replacingOccurrences(of: "()", with: "")
      .appending(".json")
  }

  static func user() -> AppPreferences {
    AppPreferences(
      hideFromDock: true,
      hideAppOnLaunch: true,
      machportIsEnabled: true,
      storageConfiguration: StorageConfiguration(path: "~/", filename: ".keyboard-cowboy.json"))
  }

  static func development() -> AppPreferences {
    AppPreferences(
      hideFromDock: false,
      hideAppOnLaunch: false,
      machportIsEnabled: true,
      storageConfiguration: StorageConfiguration(path: "~/", filename: ".keyboard-cowboy.json"))
  }

  static func emptyFile() -> AppPreferences {
    AppPreferences(
      hideFromDock: false,
      hideAppOnLaunch: false,
      machportIsEnabled: false,
      storageConfiguration: StorageConfiguration(path: rootFolder.appending("/KeyboardCowboy/Fixtures/json"),
                                                 filename: filename(for: #function)))
  }

  static func noConfiguration() -> AppPreferences {
    AppPreferences(
      hideFromDock: false,
      hideAppOnLaunch: false,
      machportIsEnabled: false,
      storageConfiguration: StorageConfiguration(path: rootFolder.appending("//jsonKeyboardCowboy/Fixtures"),
                                                 filename: filename(for: #function)))
  }

  static func noGroups() -> AppPreferences {
    AppPreferences(
      hideFromDock: false,
      hideAppOnLaunch: false,
      machportIsEnabled: false,
      storageConfiguration: StorageConfiguration(path: rootFolder.appending("/KeyboardCowboy/Fixtures/json"),
                                                 filename: filename(for: #function)))

  }

  static func designTime() -> AppPreferences {
    AppPreferences(
      hideFromDock: false,
      hideAppOnLaunch: false,
      machportIsEnabled: true,
      storageConfiguration: StorageConfiguration(path: rootFolder.appending("/KeyboardCowboy/Fixtures/json"),
                                                 filename: filename(for: #function)))
  }

  static func performance() -> AppPreferences {
    AppPreferences(
      hideFromDock: false,
      hideAppOnLaunch: false,
      machportIsEnabled: false,
      storageConfiguration: StorageConfiguration(path: rootFolder.appending("/KeyboardCowboy/Fixtures/json"),
                                                 filename: filename(for: #function)))

  }
}
