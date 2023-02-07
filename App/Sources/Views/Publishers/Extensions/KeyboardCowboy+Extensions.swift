import Cocoa

extension KeyboardCowboy {
  static let mainWindowIdentifier = "MainWindow"

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
