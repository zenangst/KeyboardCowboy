import Bonzai
import Cocoa
import SwiftUI

@MainActor
final class DebugWorkflow: NSObject, NSWindowDelegate {
  private var window: NSWindow?

  static let shared = DebugWorkflow()

  func open(_ message: String) {
    let window = createWindow()
    window.center()
    window.orderFrontRegardless()
    self.window = window
  }

  // MARK: Private methods

  private func createWindow() -> NSWindow {
    let styleMask: NSWindow.StyleMask = [.titled, .closable, .resizable, .fullSizeContentView]
    let view = Text("Debug window")
    let window = ZenSwiftUIWindow(contentRect: .zero, styleMask: styleMask) {
      view
    }
    let minSize = CGSize(width: 128 * 2.08, height: 128)
    window.setFrame(NSRect(origin: .zero, size: minSize), display: false)

    window.animationBehavior = .none
    window.backgroundColor = .clear
    window.contentAspectRatio = CGSize(width: 520, height: 250)
    window.delegate = self
    window.minSize = minSize
    window.title = "Key Viewer"
    window.titleVisibility = .hidden
    window.titlebarAppearsTransparent = true
    window.level = .statusBar
    window.standardWindowButton(.zoomButton)?.isHidden = true
    window.standardWindowButton(.miniaturizeButton)?.isHidden = true

    return window
  }

  // MARK: NSWindowDelegate

  func windowWillClose(_ notification: Notification) {
    self.window = nil
  }
}
