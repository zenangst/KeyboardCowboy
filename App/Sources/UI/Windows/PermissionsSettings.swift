import AppKit
import Bonzai

@MainActor
final class PermissionsSettings: NSObject, NSWindowDelegate {
  private var window: NSWindow?

  func show() {
    let window = ZenSwiftUIWindow(styleMask: [], content: PermissionsSettingsView())
    window.delegate = self
    self.window = window
  }

  func windowWillClose(_ notification: Notification) {
    self.window = nil
  }
}
