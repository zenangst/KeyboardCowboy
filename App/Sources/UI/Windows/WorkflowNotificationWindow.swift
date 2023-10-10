import AppKit
import SwiftUI

final class WorkflowNotificationWindow<Content>: NSPanel where Content: View {
  override var canBecomeKey: Bool { false }
  override var canBecomeMain: Bool { false }

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
    self.level = .screenSaver
    self.becomesKeyOnlyIfNeeded = true
    self.backgroundColor = .clear
    self.acceptsMouseMovedEvents = false

    let rootView = rootView()
      .ignoresSafeArea()
      .environment(\.owningWindow, self)
      .padding()

    self.contentViewController = NSHostingController(rootView: rootView)
  }
}

