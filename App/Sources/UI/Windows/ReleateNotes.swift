import AppKit
import Bonzai

@MainActor
final class ReleaseNotes: NSObject, NSWindowDelegate {
  private var window: NSWindow?

  func open() {
    let styleMask: NSWindow.StyleMask = [.titled, .closable, .fullSizeContentView]
    let window = ZenSwiftUIWindow(contentRect: .zero, styleMask: styleMask) {
      Release3_28 { action in
        switch action {
        case .done:
          self.window?.close()
        }
      }
      .onDisappear {
        AppStorageContainer.shared.releaseNotes = KeyboardCowboyApp.marketingVersion
      }
    }
    let size = window.sizeThatFits(in: .zero)
    window.setFrame(NSRect(origin: .zero, size: size), display: false)
    window.animationBehavior = .alertPanel
    window.titleVisibility = .hidden
    window.titlebarAppearsTransparent = true
    window.delegate = self

    window.center()
    window.orderFrontRegardless()
    window.makeKeyAndOrderFront(nil)

    KeyboardCowboyApp.activate()

    self.window = window
  }

  func windowWillClose(_: Notification) {
    window = nil
  }
}
