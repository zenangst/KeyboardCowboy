import AppKit
import Bonzai
import KeyCodes
import MachPort
import SwiftUI

@MainActor
final class HUDWindow: NSObject, NSWindowDelegate {
  static let instance = HUDWindow()

  private lazy var publisher = HUDNotificationPublisher(text: "")
  private var window: NSWindow?

  private override init() {
    super.init()
  }

  func open() {
    if window != nil {
      window?.orderFrontRegardless()
      return
    }

    let styleMask: NSWindow.StyleMask = [.titled, .closable, .resizable, .fullSizeContentView]
    let view = HUDNotificationView(publisher: publisher)
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
    window.title = "HUD Notification"
    window.titleVisibility = .hidden
    window.titlebarAppearsTransparent = true
    window.level = .statusBar

    window.standardWindowButton(.zoomButton)?.isHidden = true
    window.standardWindowButton(.miniaturizeButton)?.isHidden = true

    window.center()
    window.orderFrontRegardless()
    window.makeKeyAndOrderFront(nil)

    KeyboardCowboyApp.activate(setActivationPolicy: false)

    self.window = window
  }

  func windowWillClose(_ notification: Notification) {
    self.window = nil
  }
}
