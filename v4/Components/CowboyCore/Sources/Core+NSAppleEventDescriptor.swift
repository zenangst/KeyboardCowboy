import Cocoa

public extension Core {
  final class NSAppleEventDescriptor {
    let mode: Mode

    public var stringValue: String? {
      switch mode {
      case .production(let eventDescriptor): eventDescriptor.stringValue
      #if DEBUG
      case .testing: Testing.mock.stringValue
      #endif
      }
    }

    public enum Mode {
      case production(Cocoa.NSAppleEventDescriptor)
      #if DEBUG
      case testing
      #endif
    }

    public init(_ mode: Mode) {
      self.mode = mode
    }
  }
}
