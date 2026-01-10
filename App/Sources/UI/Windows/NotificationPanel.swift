import AppKit
import Combine
import SwiftUI

final class NotificationPanel<Content>: NSPanel where Content: View {
  private let manager: WindowManager
  override var canBecomeKey: Bool { false }
  override var canBecomeMain: Bool { false }

  init(animationBehavior: NSWindow.AnimationBehavior,
       styleMask: NSWindow.StyleMask = [.borderless, .nonactivatingPanel],
       content rootView: @autoclosure @escaping () -> Content) {
    manager = WindowManager()
    let contentRect = NSScreen.main?.frame ?? .init(origin: .zero, size: .init(width: 200, height: 200))
    super.init(contentRect: contentRect, styleMask: styleMask, backing: .buffered, defer: false)

    self.animationBehavior = animationBehavior
    collectionBehavior.insert(.fullScreenAuxiliary)
    collectionBehavior.insert(.canJoinAllSpaces)
    collectionBehavior.insert(.stationary)
    isOpaque = false
    isFloatingPanel = true
    isMovable = false
    isMovableByWindowBackground = false
    level = .screenSaver
    becomesKeyOnlyIfNeeded = true
    backgroundColor = .clear
    acceptsMouseMovedEvents = false
    ignoresMouseEvents = true
    hasShadow = false

    manager.window = self

    let rootView = rootView()
      .environmentObject(manager)
      .ignoresSafeArea()

    contentViewController = NSHostingController(rootView: rootView)
    setFrame(contentRect, display: false)
  }
}
