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
      .fullSizeContentView
    ]
    let window = ZenSwiftUIWindow(styleMask: styleMask, content: content)
    window.titleVisibility = .hidden
    window.titlebarAppearsTransparent = true
    window.orderFrontRegardless()
    window.center()
    window.delegate = self
    self.window = window
  }
}
