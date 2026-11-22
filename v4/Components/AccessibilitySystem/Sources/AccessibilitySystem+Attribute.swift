import CoreGraphics

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
    Self(name: "AXPosition") { value in
      guard case .point(let point) = value else {
        throw AccessibilitySystem.Failure(.malformedValue, operation: "AXPosition")
      }
      return point
    }
  }
}

public extension AccessibilitySystem.Attribute where Value == CGSize {
  static var size: Self {
    Self(name: "AXSize") { value in
      guard case .size(let size) = value else {
        throw AccessibilitySystem.Failure(.malformedValue, operation: "AXSize")
      }
      return size
    }
  }
}

public extension AccessibilitySystem.WritableAttribute where Value == Bool {
  static var main: Self { Self(name: "AXMain") }
}

public extension AccessibilitySystem.WritableAttribute where Value == String {
  static var selectedText: Self { Self(name: "AXSelectedText") }
}

public extension AccessibilitySystem.Attribute where Value == String {
  static var accessibilityDescription: Self { string(named: "AXDescription") }
  static var identifier: Self { string(named: "AXIdentifier") }
  static var title: Self { string(named: "AXTitle") }
  static var subrole: Self { string(named: "AXSubrole") }
  static var roleDescription: Self { string(named: "AXRoleDescription") }
  static var textValue: Self { string(named: "AXValue") }
  static var selectedText: Self { string(named: "AXSelectedText") }

  private static func string(named name: String) -> Self {
    Self(name: name) { value in
      guard case .string(let text) = value else {
        throw AccessibilitySystem.Failure(.malformedValue, operation: name)
      }
      return text
    }
  }
}
