import Foundation

public enum AccessibilitySystem {}

public extension AccessibilitySystem.Attribute where Value == String {
  static var role: Self {
    Self(name: "AXRole") { value in
      guard case .string(let result) = value else {
        throw AccessibilitySystem.Failure(.malformedValue, operation: "AXRole")
      }

      return result
    }
  }
}

public extension AccessibilitySystem.Attribute where Value == URL {
  static var url: Self {
    Self(name: "AXURL") { value in
      guard case .url(let result) = value else {
        throw AccessibilitySystem.Failure(.malformedValue, operation: "AXURL")
      }

      return result
    }
  }
}
