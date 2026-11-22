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
