import AppKit
import Bonzai

@MainActor
final class PermissionsSettings: NSObject, NSWindowDelegate {
  private var window: NSWindow?

  func show() {
    let styleMask: NSWindow.StyleMask = [.closable, .miniaturizable, .resizable, .titled]
    let window = ZenSwiftUIWindow(styleMask: styleMask, content: PermissionsSettingsView())
    window.animationBehavior = .utilityWindow
    window.titleVisibility = .hidden
    window.titlebarAppearsTransparent = true
    window.delegate = self
    window.orderFrontRegardless()
    window.center()

    self.window = window
  }

  func windowWillClose(_ notification: Notification) {
    self.window = nil
  }
}
