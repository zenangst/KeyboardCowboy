import Cocoa
import SwiftUI

private struct OwningWindowKey: EnvironmentKey {
    static let defaultValue: NSPanel? = nil
}

extension EnvironmentValues {
  var owningWindow: NSPanel? {
    get { self[OwningWindowKey.self] }
    set { self[OwningWindowKey.self] = newValue }
  }
}

final class NotificationWindow<Content>: NSPanel where Content: View {
  override var canBecomeKey: Bool { true }
  override var canBecomeMain: Bool { true }

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

    contentView.wantsLayer = true
    contentView.layer?.cornerRadius = 8
    contentView.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
    contentView.layer?.masksToBounds = true
  }
}
