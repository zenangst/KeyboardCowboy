public extension AccessibilitySystem {
  struct Attribute<Value> {
    let name: String
    let decode: (ReadValue) throws -> Value
  }

  struct WritableAttribute<Value> {
    let name: String
  }
}

public extension AccessibilitySystem.WritableAttribute where Value == Bool {
  static var main: Self { Self(name: "AXMain") }
}

public extension AccessibilitySystem.WritableAttribute where Value == String {
  static var selectedText: Self { Self(name: "AXSelectedText") }
}

public extension AccessibilitySystem.Attribute where Value == String {
  static var textValue: Self {
    Self(name: "AXValue") { value in
      guard case .string(let text) = value else {
        throw AccessibilitySystem.Failure(.malformedValue, operation: "AXValue")
      }
      return text
    }
  }

  static var selectedText: Self {
    Self(name: "AXSelectedText") { value in
      guard case .string(let text) = value else {
        throw AccessibilitySystem.Failure(.malformedValue, operation: "AXSelectedText")
      }
      return text
    }
  }
}
