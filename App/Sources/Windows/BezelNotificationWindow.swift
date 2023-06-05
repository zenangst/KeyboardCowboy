import AppKit
import SwiftUI

final class BezelNotificationWindow<Content>: NSPanel where Content: View {
  override var canBecomeKey: Bool { true }
  override var canBecomeMain: Bool { true }

  convenience init(contentRect: CGRect,
       content rootView: @autoclosure @escaping () -> Content) {
    self.init(contentRect: contentRect, content: { rootView() })
  }

  init(contentRect: CGRect,
       content rootView: @escaping () -> Content) {
    super.init(contentRect: contentRect, styleMask: [
      .borderless, .nonactivatingPanel
    ], backing: .buffered, defer: false)

    self.animationBehavior = .utilityWindow
    self.collectionBehavior.insert(.fullScreenAuxiliary)
    self.isOpaque = false
    self.isFloatingPanel = true
    self.isMovable = false
    self.isMovableByWindowBackground = false
    self.level = .floating
    self.backgroundColor = .clear

    let contentView = NSHostingView(
      rootView: rootView()
        .ignoresSafeArea()
        .environment(\.owningWindow, self)
    )
    contentView.isFlipped = true

    self.contentView = contentView
  }
}
