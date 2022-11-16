import Cocoa

extension KeyboardCowboy {
  static private var app: NSApplication = .shared

  static var keyWindow: NSWindow? {
    KeyboardCowboy.app.keyWindow
  }
  static var mainWindow: NSWindow? {
    KeyboardCowboy.app.windows
      .first(where: { $0.identifier?.rawValue.contains("MainWindow") == true })
  }

  static func activate() {
    Self.app.activate(ignoringOtherApps: true)
  }
}
