import ApplicationServices
import Foundation

public extension AccessibilitySystem {
  struct Attribute<Value> {
    let name: String
    let decode: (ReadValue) throws -> Value
  }

  struct WritableAttribute<Value> {
    let name: String
  }
}

public extension AccessibilitySystem.Attribute where Value == CGPoint {
  /// Top-left origin in AX global screen coordinates.
  static var position: Self {
    Self(name: kAXPositionAttribute) { value in
      guard case .point(let point) = value else {
        throw AccessibilitySystem.Failure(.malformedValue, operation: kAXPositionAttribute)
      }

      return point
    }
  }
}

public extension AccessibilitySystem.Attribute where Value == CGSize {
  static var size: Self {
    Self(name: kAXSizeAttribute) { value in
      guard case .size(let size) = value else {
        throw AccessibilitySystem.Failure(.malformedValue, operation: kAXSizeAttribute)
      }

      return size
    }
  }
}

public extension AccessibilitySystem.Attribute where Value == NSRange {
  static var selectedTextRange: Self {
    Self(name: kAXSelectedTextRangeAttribute) { value in
      guard case .range(let range) = value else {
        throw AccessibilitySystem.Failure(.malformedValue, operation: kAXSelectedTextRangeAttribute)
      }

      return range
    }
  }
}

public extension AccessibilitySystem.WritableAttribute where Value == Bool {
  static var main: Self { Self(name: kAXMainAttribute) }
}

public extension AccessibilitySystem.WritableAttribute where Value == CGPoint {
  static var position: Self { Self(name: kAXPositionAttribute) }
}

public extension AccessibilitySystem.WritableAttribute where Value == CGSize {
  static var size: Self { Self(name: kAXSizeAttribute) }
}

public extension AccessibilitySystem.Attribute where Value == Bool {
  static var enabled: Self { boolean(named: kAXEnabledAttribute) }
  static var focused: Self { boolean(named: kAXFocusedAttribute) }
  static var selected: Self { boolean(named: kAXSelectedAttribute) }

  private static func boolean(named name: String) -> Self {
    Self(name: name) { value in
      guard case .bool(let flag) = value else {
        throw AccessibilitySystem.Failure(.malformedValue, operation: name)
      }

      return flag
    }
  }
}

public extension AccessibilitySystem.WritableAttribute where Value == String {
  static var selectedText: Self { Self(name: kAXSelectedTextAttribute) }
}

public extension AccessibilitySystem.Attribute where Value == String {
  static var accessibilityDescription: Self { string(named: kAXDescriptionAttribute) }
  static var identifier: Self { string(named: kAXIdentifierAttribute) }
  static var title: Self { string(named: kAXTitleAttribute) }
  static var subrole: Self { string(named: kAXSubroleAttribute) }
  static var roleDescription: Self { string(named: kAXRoleDescriptionAttribute) }
  static var textValue: Self { string(named: kAXValueAttribute) }
  static var selectedText: Self { string(named: kAXSelectedTextAttribute) }

  private static func string(named name: String) -> Self {
    Self(name: name) { value in
      guard case .string(let text) = value else {
        throw AccessibilitySystem.Failure(.malformedValue, operation: name)
      }

      return text
    }
  }
}
