import Cocoa

@MainActor
struct AppPreferences {
  static var config: AppPreferences {
    if KeyboardCowboyApp.isRunningTests {
      return AppPreferences.unitTests()
    }

    switch KeyboardCowboyApp.env() {
    case .development: return AppPreferences.designTime()
    case .previews: return AppPreferences.designTime()
    case .production: return AppPreferences.user()
    }
  }

  var hideAppOnLaunch: Bool = true
  var machportIsEnabled = true
  var configLocation: ConfigurationLocation

  private static func filename(for functionName: StaticString) -> String {
    "\(functionName)"
      .replacingOccurrences(of: "()", with: "")
      .appending(".json")
  }

  static func user() -> AppPreferences {
    AppPreferences(
      hideAppOnLaunch: true,
      machportIsEnabled: true,
      configLocation: .user,
    )
  }

  static func development() -> AppPreferences {
    AppPreferences(
      hideAppOnLaunch: false,
      machportIsEnabled: true,
      configLocation: .user,
    )
  }

  static func unitTests() -> AppPreferences {
    AppPreferences(
      hideAppOnLaunch: false,
      machportIsEnabled: false,
      configLocation: .unitTests,
    )
  }

  static func emptyFile() -> AppPreferences {
    AppPreferences(
      hideAppOnLaunch: false,
      machportIsEnabled: false,
      configLocation: ConfigurationLocation(path: rootFolder.appending("/KeyboardCowboy/Fixtures/json"),
                                            filename: filename(for: #function)),
    )
  }

  static func noConfiguration() -> AppPreferences {
    AppPreferences(
      hideAppOnLaunch: false,
      machportIsEnabled: false,
      configLocation: ConfigurationLocation(path: rootFolder.appending("//jsonKeyboardCowboy/Fixtures"),
                                            filename: filename(for: #function)),
    )
  }

  static func noGroups() -> AppPreferences {
    AppPreferences(
      hideAppOnLaunch: false,
      machportIsEnabled: false,
      configLocation: ConfigurationLocation(path: rootFolder.appending("/KeyboardCowboy/Fixtures/json"),
                                            filename: filename(for: #function)),
    )
  }

  static func designTime() -> AppPreferences {
    AppPreferences(
      hideAppOnLaunch: false,
      machportIsEnabled: true,
      configLocation: .designTime,
    )
  }

  static func performance() -> AppPreferences {
    AppPreferences(
      hideAppOnLaunch: false,
      machportIsEnabled: false,
      configLocation: ConfigurationLocation(path: rootFolder.appending("/KeyboardCowboy/Fixtures/json"),
                                            filename: filename(for: #function)),
    )
  }
}
