import Cocoa
import CowboyCore

extension AppleScript {
  final class Cache {
    private var storage = [String: Core.NSAppleScript]()

    init() {}

    func appleScript(for key: String) -> Core.NSAppleScript? {
      storage[key]
    }

    func get(for key: String) -> Core.NSAppleScript? {
      storage[key]
    }

    func set(_ appleScript: Core.NSAppleScript, for key: String) {
      storage[key] = appleScript
    }

    func clear() {
      storage.removeAll()
    }
  }
}
