import AppKit
import Bonzai

@MainActor
final class PermissionsSettings: NSObject, NSWindowDelegate {
  private var window: NSWindow?

  func show() {
    let styleMask: NSWindow.StyleMask = [.closable, .miniaturizable, .resizable, .titled, .fullSizeContentView]
    let window = ZenSwiftUIWindow(styleMask: styleMask) {
      PermissionsSettingsView()
        .style(.derived)
        .frame(minWidth: 400)
    }
    window.animationBehavior = .utilityWindow
    window.titleVisibility = .hidden
    window.titlebarAppearsTransparent = true
    window.delegate = self
    window.orderFrontRegardless()
    window.center()

    window.standardWindowButton(.miniaturizeButton)?.isHidden = true
    window.standardWindowButton(.zoomButton)?.isHidden = true

    self.window = window
  }

  func windowWillClose(_: Notification) {
    window = nil
  }
}
