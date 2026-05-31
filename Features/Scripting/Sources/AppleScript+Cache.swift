import Cocoa
import CowboyCore

extension AppleScript {
  final class Cache {
    private let env: Core.Environment
    private var storage = [String: Core.NSAppleScript]()

    public enum Testing {
      @TaskLocal public static var mock: Mock = Mock()
    }

    public struct Mock: Sendable {
      var clear: @Sendable () -> Void = {}
      var entryForKey: Core.NSAppleScript?
    }

    init(_ env: Core.Environment) {
      self.env = env
    }

    func appleScript(for key: String) -> Core.NSAppleScript? {
      switch env {
      case .production: storage[key]
      case .testing: Testing.mock.entryForKey
      }
    }

    func get(for key: String) -> Core.NSAppleScript? {
      storage[key]
    }

    func set(_ appleScript: Core.NSAppleScript, for key: String) {
      storage[key] = appleScript
    }

    func clear() {
      switch env {
      case .production: storage.removeAll()
      case .testing: Testing.mock.clear()
      }
    }
  }
}
