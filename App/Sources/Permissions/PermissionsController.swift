import Cocoa

protocol PermissionsControlling {
  func hasPrivileges() -> Bool
}

final class PermissionsController: PermissionsControlling {
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
    let applicationName = ProcessInfo.processInfo.processName
    let alert = NSAlert()
    alert.messageText = "Enable Accessibility"
    alert.informativeText = """
    \(applicationName) requires access to accessibility.

    To enable this, click on \"Open System Preferences\" on the dialog that just appeared.

    When the setting is enabled, restart \(applicationName) and you should be ready to go.
    """
    alert.alertStyle = .warning
    alert.addButton(withTitle: "Quit")
    alert.runModal()
  }
}
