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
    func focusedElement() throws -> Handle
    func element(at point: CGPoint) throws -> Handle
    func setTimeout(_ seconds: Float, on handle: Handle) throws
    func read(_ name: String, from handle: Handle) throws -> ReadValue
    func perform(_ action: Action, on handle: Handle) throws
    func write(_ name: String, value: Bool, to handle: Handle) throws
    func write(_ name: String, value: String, to handle: Handle) throws
  }

  struct NativeTransport: Transport {
    func application(_ pid: Int32) -> Handle {
      Handle(native: AXUIElementCreateApplication(pid))
    }

    func focusedElement() throws -> Handle {
      let name = kAXFocusedUIElementAttribute
      let system = AXUIElementCreateSystemWide()
      var value: CFTypeRef?
      try check(AXUIElementCopyAttributeValue(system, name as CFString, &value), operation: name)
      guard let value, CFGetTypeID(value) == AXUIElementGetTypeID() else {
        throw Failure(.malformedValue, operation: name)
      }

      return Handle(native: (value as! AXUIElement)) // swiftlint:disable:this force_cast
    }

    func element(at point: CGPoint) throws -> Handle {
      let operation = "elementAtPosition"
      let x = Float(point.x)
      let y = Float(point.y)
      guard x.isFinite, y.isFinite else {
        throw Failure(.invalidConfiguration, operation: operation)
      }

      var element: AXUIElement?
      try check(AXUIElementCopyElementAtPosition(AXUIElementCreateSystemWide(), x, y, &element),
                operation: operation)
      guard let element else { throw Failure(.malformedValue, operation: operation) }
      return Handle(native: element)
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

    func perform(_ action: Action, on handle: Handle) throws {
      let name = switch action {
      case .raise: kAXRaiseAction
      }
      guard let native = handle.native else {
        throw Failure(.invalidElement, operation: name)
      }

      try check(AXUIElementPerformAction(native, name as CFString), operation: name)
    }

    func write(_ name: String, value: Bool, to handle: Handle) throws {
      try setAttribute(name, value: value ? kCFBooleanTrue : kCFBooleanFalse, on: handle)
    }

    func write(_ name: String, value: String, to handle: Handle) throws {
      try setAttribute(name, value: value as CFString, on: handle)
    }

    private func setAttribute(_ name: String, value: CFTypeRef, on handle: Handle) throws {
      guard let native = handle.native else {
        throw Failure(.invalidElement, operation: name)
      }

      try check(AXUIElementSetAttributeValue(native, name as CFString, value), operation: name)
    }

    // Type IDs are checked before every Foundation/Core Foundation conversion.
    static func decode(_ value: CFTypeRef?, operation name: String) throws -> ReadValue {
      guard let value else { throw Failure(.malformedValue, operation: name) }

      switch CFGetTypeID(value) {
      case CFStringGetTypeID():
        guard let string = value as? String else {
          throw Failure(.malformedValue, operation: name)
        }
        return .string(string)
      case CFURLGetTypeID():
        guard let url = value as? URL else {
          throw Failure(.malformedValue, operation: name)
        }
        return .url(url)
      case CFArrayGetTypeID():
        guard let values = value as? [CFTypeRef] else {
          throw Failure(.malformedValue, operation: name)
        }

        let handles = try values.map { value -> Handle in
          guard CFGetTypeID(value) == AXUIElementGetTypeID() else {
            throw Failure(.malformedValue, operation: name)
          }
          // Swift cannot conditionally cast an opaque CF type; the type ID
          // check above validates this cast before it is performed.
          return Handle(native: (value as! AXUIElement)) // swiftlint:disable:this force_cast
        }
        return .elements(handles)
      default:
        throw Failure(.malformedValue, operation: name)
      }
    }

    private func check(_ status: AXError, operation: String) throws {
      guard status != .success else { return }

      let kind: Failure.Kind = switch status {
      case .noValue: .noValue
      case .attributeUnsupported: .attributeUnsupported
      case .actionUnsupported: .actionUnsupported
      case .invalidUIElement: .invalidElement
      case .apiDisabled: .apiDisabled
      case .cannotComplete: .cannotComplete
      default: .other
      }
      throw Failure(kind, operation: operation, rawAXStatus: status.rawValue)
    }
  }
}
