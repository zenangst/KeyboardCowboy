import Cocoa

protocol PermissionsControlling {
  func hasPrivileges() -> Bool
}

class PermissionsController: PermissionsControlling {
  func hasPrivileges() -> Bool {
    let options: [String: Bool] = [
      kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true
    ]
    return AXIsProcessTrustedWithOptions(options as CFDictionary)
  }

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
