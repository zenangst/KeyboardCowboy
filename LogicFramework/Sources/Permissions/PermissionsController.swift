import Cocoa

public protocol PermissionsControlling {
  func hasPrivileges() -> Bool
}

final class PermissionsController: NSObject, PermissionsControlling, NSAlertDelegate {
  /// Check if the application has the permissions to use accessiblity
  /// - Returns: True if the application has been granted permissions.
  func hasPrivileges() -> Bool {
    let options: [String: Bool] = [
      kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true
    ]
    return AXIsProcessTrustedWithOptions(options as CFDictionary)
  }
}
