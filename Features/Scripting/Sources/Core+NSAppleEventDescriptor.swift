import Cocoa
import CowboyCore

extension Core {
  final class NSAppleEventDescriptor {
    let mode: Mode

    public enum Testing {
      @TaskLocal public static var mock: Mock = Mock()
    }

    public struct Mock: Sendable {
      var stringValue: String?
    }

    var stringValue: String? {
      switch mode {
      case .production(let eventDescriptor): eventDescriptor.stringValue
      case .testing: Testing.mock.stringValue
      }
    }

    enum Mode {
      case production(Cocoa.NSAppleEventDescriptor)
      case testing
    }

    init(_ mode: Mode) {
      self.mode = mode
    }
  }
}
