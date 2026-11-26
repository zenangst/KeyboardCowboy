import ApplicationServices
import Foundation

extension AccessibilitySystem {
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

    func bounds(for range: NSRange, from handle: Handle) throws -> CGRect {
      let name = kAXBoundsForRangeParameterizedAttribute
      guard range.location >= 0, range.location != NSNotFound, range.length >= 0,
            range.length <= Int.max - range.location else {
        throw Failure(.invalidConfiguration, operation: name)
      }
      guard let native = handle.native else { throw Failure(.invalidElement, operation: name) }

      var parameter = CFRange(location: range.location, length: range.length)
      guard let argument = AXValueCreate(.cfRange, &parameter) else {
        throw Failure(.malformedValue, operation: name)
      }

      var value: CFTypeRef?
      try check(AXUIElementCopyParameterizedAttributeValue(native, name as CFString, argument, &value), operation: name)
      guard case .rect(let rect) = try Self.decode(value, operation: name) else {
        throw Failure(.malformedValue, operation: name)
      }

      return rect
    }

    func perform(_ action: Action, on handle: Handle) throws {
      let name = switch action {
      case .raise: kAXRaiseAction
      case .press: kAXPressAction
      case .pick: kAXPickAction
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

    func write(_ name: String, value: CGPoint, to handle: Handle) throws {
      var point = value
      guard let geometry = AXValueCreate(.cgPoint, &point) else {
        throw Failure(.malformedValue, operation: name)
      }

      try setAttribute(name, value: geometry, on: handle)
    }

    func write(_ name: String, value: CGSize, to handle: Handle) throws {
      var size = value
      guard let geometry = AXValueCreate(.cgSize, &size) else {
        throw Failure(.malformedValue, operation: name)
      }

      try setAttribute(name, value: geometry, on: handle)
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
      case CFBooleanGetTypeID():
        return .bool(CFEqual(value, kCFBooleanTrue))
      case AXUIElementGetTypeID():
        return .element(Handle(native: (value as! AXUIElement))) // swiftlint:disable:this force_cast
      case AXValueGetTypeID():
        let geometry = value as! AXValue // swiftlint:disable:this force_cast
        switch AXValueGetType(geometry) {
        case .cgPoint:
          var point = CGPoint.zero
          if AXValueGetValue(geometry, .cgPoint, &point), point.x.isFinite, point.y.isFinite {
            return .point(point)
          }
        case .cgSize:
          var size = CGSize.zero
          if AXValueGetValue(geometry, .cgSize, &size),
             size.width.isFinite, size.height.isFinite, size.width >= 0, size.height >= 0 {
            return .size(size)
          }
        case .cfRange:
          var range = CFRange()
          if AXValueGetValue(geometry, .cfRange, &range),
             range.location >= 0, range.location != NSNotFound, range.length >= 0,
             range.length <= Int.max - range.location {
            return .range(NSRange(location: range.location, length: range.length))
          }
        case .cgRect:
          var rect = CGRect.zero
          if AXValueGetValue(geometry, .cgRect, &rect),
             rect.origin.x.isFinite, rect.origin.y.isFinite,
             rect.size.width.isFinite, rect.size.height.isFinite,
             rect.size.width >= 0, rect.size.height >= 0,
             rect.maxX.isFinite, rect.maxY.isFinite {
            return .rect(rect)
          }
        default:
          break
        }
        throw Failure(.malformedValue, operation: name)
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
