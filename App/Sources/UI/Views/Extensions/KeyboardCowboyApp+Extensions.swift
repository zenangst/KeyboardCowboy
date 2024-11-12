import Cocoa

extension KeyboardCowboyApp {
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
    KeyboardCowboyApp.app.windows
      .first(where: { $0.identifier?.rawValue.contains(mainWindowIdentifier) == true })
  }

  static func activate(setActivationPolicy: Bool = true) {
    if setActivationPolicy {
      Self.app.setActivationPolicy(.regular)
    }
    Self.app.activate(ignoringOtherApps: true)
    NSWorkspace.shared.open(Bundle.main.bundleURL)
  }

  static func deactivate() {
    Self.app.setActivationPolicy(.accessory)
  }

  // MARK: Private variables

  static private var app: NSApplication = .shared

}
