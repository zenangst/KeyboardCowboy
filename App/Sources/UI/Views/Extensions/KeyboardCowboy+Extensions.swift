import Cocoa

extension KeyboardCowboy {
  static let mainWindowIdentifier = "MainWindow"
  static let permissionsSettingsWindowIdentifier = "PermissionsSettingsWindow"
  static let permissionsWindowIdentifier = "PermissionsWindow"
  static let releaseNotesWindowIdentifier = "ReleaseNotesWindow"

  static var bundleIdentifier: String { Bundle.main.bundleIdentifier! }

  static var marektingVersion: String {
    Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String
  }

  static var buildNumber: String {
    Bundle.main.infoDictionary!["CFBundleVersion"] as! String
  }

  static var keyWindow: NSWindow? {
    KeyboardCowboy.app.keyWindow
  }
  static var mainWindow: NSWindow? {
    KeyboardCowboy.app.windows
      .first(where: { $0.identifier?.rawValue.contains(mainWindowIdentifier) == true })
  }

  static func activate() {
    Self.app.setActivationPolicy(.regular)
    Self.app.activate(ignoringOtherApps: true)
  }

  static func deactivate() {
    Self.app.setActivationPolicy(.accessory)
  }

  // MARK: Private variables

  static private var app: NSApplication = .shared

}
