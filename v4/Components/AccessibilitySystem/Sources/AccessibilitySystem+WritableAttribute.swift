import ApplicationServices

public extension AccessibilitySystem {
  struct WritableAttribute<Value> {
    let name: String
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

public extension AccessibilitySystem.WritableAttribute where Value == String {
  static var selectedText: Self { Self(name: kAXSelectedTextAttribute) }
}
