import AppleScriptSystem
import Cocoa
import CowboyCore

extension AppleScript {
  struct Cache {
    private var storage = [String: Core.NSAppleScript]()

    init() {}

    func get(for key: String) -> Core.NSAppleScript? {
      storage[key]
    }

    mutating func set(_ appleScript: Core.NSAppleScript, for key: String) {
      storage[key] = appleScript
    }

    mutating func clear() {
      storage.removeAll()
    }
  }
}
