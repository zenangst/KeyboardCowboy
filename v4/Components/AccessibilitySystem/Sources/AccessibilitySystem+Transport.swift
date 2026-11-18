import ApplicationServices
import Foundation

extension AccessibilitySystem {
  // Neither transport values nor native handles cross the serial-worker boundary.
  final class Handle: Hashable {
    let native: AXUIElement?
    private let fixtureIdentity: UUID

    init(native: AXUIElement? = nil) {
      self.native = native
      fixtureIdentity = UUID()
    }

    static func == (lhs: Handle, rhs: Handle) -> Bool {
      if let left = lhs.native, let right = rhs.native { return CFEqual(left, right) }
      return lhs.fixtureIdentity == rhs.fixtureIdentity
    }

    func hash(into hasher: inout Hasher) {
      if let native {
        hasher.combine(CFHash(native))
      } else {
        hasher.combine(fixtureIdentity)
      }
    }
  }

  enum ReadValue {
    case string(String), url(URL), elements([Handle]), malformed
  }

  protocol Transport {
    func application(_ pid: Int32) -> Handle
    func setTimeout(_ seconds: Float, on handle: Handle) throws
    func read(_ name: String, from handle: Handle) throws -> ReadValue
  }

  struct NativeTransport: Transport {
    func application(_ pid: Int32) -> Handle {
      Handle(native: AXUIElementCreateApplication(pid))
    }

    func setTimeout(_ seconds: Float, on handle: Handle) throws {
      guard let native = handle.native else {
        throw Failure(.invalidElement, operation: "setMessagingTimeout")
      }

      try check(AXUIElementSetMessagingTimeout(native, seconds), operation: "setMessagingTimeout")
    }

    func read(_ name: String, from handle: Handle) throws -> ReadValue {
      guard let native = handle.native else {
        throw Failure(.invalidElement, operation: name)
      }

      var value: CFTypeRef?
      try check(AXUIElementCopyAttributeValue(native, name as CFString, &value), operation: name)
      return try Self.decode(value, operation: name)
    }

    // Type IDs are checked before every Foundation/Core Foundation conversion.
    static func decode(_ value: CFTypeRef?, operation name: String) throws -> ReadValue {
      guard let value else { throw Failure(.malformedValue, operation: name) }

      switch CFGetTypeID(value) {
      case CFStringGetTypeID():
        return .string(value as! String)
      case CFURLGetTypeID():
        return .url(value as! URL)
      case CFArrayGetTypeID():
        let values = value as! [CFTypeRef]
        guard values.allSatisfy({ CFGetTypeID($0) == AXUIElementGetTypeID() }) else {
          throw Failure(.malformedValue, operation: name)
        }

        return .elements(values.map { Handle(native: ($0 as! AXUIElement)) })
      default:
        throw Failure(.malformedValue, operation: name)
      }
    }

    private func check(_ status: AXError, operation: String) throws {
      guard status != .success else { return }

      let kind: Failure.Kind = switch status {
      case .noValue: .noValue
      case .attributeUnsupported: .attributeUnsupported
      case .invalidUIElement: .invalidElement
      case .apiDisabled: .apiDisabled
      case .cannotComplete: .cannotComplete
      default: .other
      }
      throw Failure(kind, operation: operation, rawAXStatus: status.rawValue)
    }
  }
}
