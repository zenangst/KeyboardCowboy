import ApplicationServices
import Foundation

public enum AccessibilitySystem {}

public extension AccessibilitySystem.Attribute where Value == AccessibilitySystem.Role {
  static var role: Self {
    Self(name: kAXRoleAttribute) { value in
      guard case .string(let result) = value else {
        throw AccessibilitySystem.Failure(.malformedValue, operation: kAXRoleAttribute)
      }

      return AccessibilitySystem.Role(rawValue: result)
    }
  }
}

public extension AccessibilitySystem.Attribute where Value == URL {
  static var url: Self {
    Self(name: kAXURLAttribute) { value in
      guard case .url(let result) = value else {
        throw AccessibilitySystem.Failure(.malformedValue, operation: kAXURLAttribute)
      }

      return result
    }
  }
}
