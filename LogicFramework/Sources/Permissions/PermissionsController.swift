import Cocoa

public protocol PermissionsControlling {
  var informativeText: String { get }
  func hasPrivileges() -> Bool
}

final class PermissionsController: PermissionsControlling {
  var applicationName = ProcessInfo.processInfo.processName
  var informativeText: String {
    """
    \(applicationName) requires access to accessibility.

    To enable this, click on \"Open System Preferences\" on the dialog that just appeared.

    When the setting is enabled, restart \(applicationName) and you should be ready to go.
    """
  }

  /// Check if the application has the permissions to use accessiblity
  /// - Returns: True if the application has been granted permissions.
  func hasPrivileges() -> Bool {
    let options: [String: Bool] = [
      kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true
    ]
    return AXIsProcessTrustedWithOptions(options as CFDictionary)
  }

  /// Display modal message using `NSAlert` and ask the user to provide
  /// accessibility permissions for the application
  func displayModal() {
    let alert = NSAlert()
    alert.messageText = "Enable Accessibility"
    alert.informativeText = informativeText
    alert.alertStyle = .warning
    alert.addButton(withTitle: "Quit")
    alert.runModal()
  }
}
