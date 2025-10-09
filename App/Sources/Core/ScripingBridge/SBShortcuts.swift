import Cocoa
import ScriptingBridge

enum SBShortcutsError: Error {
  case unableToCreateApplication
  case unableToGetShortcuts
  case unableToCreateShortcut
  case unableToOpenShortcut
}

// Inspiration for this implementation is credited to https://github.com/swiftbar/SwiftBar 👏
enum SBShortcuts {
  static func getShortcuts() throws -> [Shortcut] {
    guard let application: SBApp = SBApplication(bundleIdentifier: "com.apple.shortcuts.events") else {
      throw SBShortcutsError.unableToCreateApplication
    }
    guard let sbShortcuts = application.shortcuts?.get() else {
      throw SBShortcutsError.unableToGetShortcuts
    }

    var shortcuts = [Shortcut]()
    for shortcut in sbShortcuts {
      guard let ref = shortcut as? SBShortcut,
            let name = ref.name else { continue }

      let shortcut = Shortcut(name: name)
      shortcuts.append(shortcut)
    }

    return shortcuts
  }

  static func openShortcut(_ name: String) throws {
    var components = URLComponents()
    components.scheme = "shortcuts"
    components.host = "open-shortcut"
    components.queryItems = [
      URLQueryItem(name: "name", value: name),
    ]
    guard let url = components.url else {
      throw SBShortcutsError.unableToOpenShortcut
    }

    NSWorkspace.shared.open(url)
  }

  static func createShortcut() throws {
    guard let url = URL(string: "shortcuts://create-shortcut") else {
      throw SBShortcutsError.unableToOpenShortcut
    }

    NSWorkspace.shared.open(url)
  }
}

@objc private protocol SBApp {
  @objc optional var shortcuts: SBElementArray { get }
}

extension SBApplication: SBApp {}
extension SBObject: SBShortcut {}

@objc protocol SBShortcut {
  @objc optional var id: String { get }
  @objc optional var name: String { get }
  @objc optional func run(withInput: Any?) -> Any?
}
