import AppKit

extension KeyboardCowboyApp {
  #if DEBUG
    static func env() -> AppEnvironment {
      guard !isRunningPreview else { return .previews }

      if let override = ProcessInfo.processInfo.environment["APP_ENVIRONMENT_OVERRIDE"],
         let env = AppEnvironment(rawValue: override)
      {
        return env
      } else {
        return .production
      }
    }
  #else
    static func env() -> AppEnvironment { .production }
  #endif

  static let mainWindowIdentifier = "MainWindow"
  static let permissionsSettingsWindowIdentifier = "PermissionsSettingsWindow"
  static let emptyConfigurationWindowIdentifier = "EmptyConfigurationWindow"
  static let permissionsWindowIdentifier = "PermissionsWindow"
  static let releaseNotesWindowIdentifier = "ReleaseNotesWindow"
  static let userModeWindowIdentifier = "UserModeWindow"

  static var bundleIdentifier: String { Bundle.main.bundleIdentifier! }

  static var marketingVersion: String {
    Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String
  }

  static var buildNumber: String {
    Bundle.main.infoDictionary!["CFBundleVersion"] as! String
  }

  static var keyWindow: NSWindow? {
    KeyboardCowboyApp.app.keyWindow
  }

  static var mainWindow: NSWindow? {
    KeyboardCowboyApp.app
      .windows
      .first(where: { $0.identifier?.rawValue.contains(mainWindowIdentifier) == true })
  }

  static func activate(setActivationPolicy: Bool = true) {
    if setActivationPolicy {
      app.setActivationPolicy(.regular)
    }
    app.activate(ignoringOtherApps: true)
    NSWorkspace.shared.open(Bundle.main.bundleURL)
  }

  static func deactivate() {
    app.setActivationPolicy(.accessory)
  }

  // MARK: Private variables

  private static var app: NSApplication = .shared
}
