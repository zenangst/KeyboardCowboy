import Cocoa

extension AppleScript {
  @MainActor final class Cache {
    private var storage = [String: NSAppleScript]()

    func clear() {}
  }
}
