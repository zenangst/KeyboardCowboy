import AppKit
import Bonzai
import SwiftUI

@MainActor
final class EmptyConfiguration: NSObject, NSWindowDelegate {
  private var window: NSWindow?
  private let store: ContentStore

  init(store: ContentStore) {
    self.store = store
  }

  func open() {
    let content = EmptyConfigurationView(onAction: store.handle(_:))
    let styleMask: NSWindow.StyleMask = [
      .closable,
      .miniaturizable,
      .resizable,
      .titled,
      .fullSizeContentView
    ]
    let window = ZenSwiftUIWindow(styleMask: styleMask, content: content)
    let size = window.hostingController.sizeThatFits(in: .zero)
    window.setFrame(NSRect(origin: .zero, size: size), display: false)
    window.titleVisibility = .visible
    window.titlebarAppearsTransparent = true
    window.toolbarStyle = .unifiedCompact
    window.orderFrontRegardless()
    window.center()
    window.delegate = self
    self.window = window
  }

  func windowWillClose(_ notification: Notification) {
    self.window = nil
  }
}
