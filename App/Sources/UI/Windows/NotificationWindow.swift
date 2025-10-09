import AppKit
import Combine
import SwiftUI

final class NotificationWindow<Content>: NSWindow where Content: View {
  private let manager: WindowManager
  override var canBecomeKey: Bool { false }
  override var canBecomeMain: Bool { false }

  init(animationBehavior: NSWindow.AnimationBehavior,
       content rootView: @autoclosure @escaping () -> Content)
  {
    manager = WindowManager()
    let contentRect = NSScreen.main?.frame ?? .init(origin: .zero, size: .init(width: 200, height: 200))
    super.init(contentRect: contentRect, styleMask: [
      .borderless, .nonactivatingPanel,
    ], backing: .buffered, defer: false)

    self.animationBehavior = animationBehavior
    collectionBehavior.insert(.fullScreenAuxiliary)
    isOpaque = false
    isMovable = false
    isMovableByWindowBackground = false
    level = .screenSaver
    backgroundColor = .clear
    acceptsMouseMovedEvents = false
    hasShadow = false

    manager.window = self

    let rootView = rootView()
      .environmentObject(manager)
      .ignoresSafeArea()

    contentViewController = NSHostingController(rootView: rootView)
    setFrame(contentRect, display: false)
  }
}
