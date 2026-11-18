import AppleScriptRuntime
import Cocoa

extension AppleScript {
  struct Cache {
    private var storage = [String: AppleScriptRuntime.NSAppleScript]()

    init() {}

    func get(for key: String) -> AppleScriptRuntime.NSAppleScript? {
      storage[key]
    }

    mutating func set(_ appleScript: AppleScriptRuntime.NSAppleScript, for key: String) {
      storage[key] = appleScript
    }

    mutating func clear() {
      storage.removeAll()
    }
  }
}
