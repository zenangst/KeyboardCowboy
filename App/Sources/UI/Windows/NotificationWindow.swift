import AppKit
import Combine
import SwiftUI

final class NotificationWindow<Content>: NSPanel where Content: View {
  private let manager: WindowManager
  override var canBecomeKey: Bool { false }
  override var canBecomeMain: Bool { false }

  init(animationBehavior: NSWindow.AnimationBehavior,
       content rootView: @autoclosure @escaping () -> Content) {
    self.manager = WindowManager()
    let contentRect = NSScreen.main?.frame ?? .init(origin: .zero, size: .init(width: 200, height: 200))
    super.init(contentRect: contentRect, styleMask: [
      .borderless, .nonactivatingPanel
    ], backing: .buffered, defer: false)

    self.animationBehavior = animationBehavior
    self.collectionBehavior.insert(.fullScreenAuxiliary)
    self.isOpaque = false
    self.isFloatingPanel = true
    self.isMovable = false
    self.isMovableByWindowBackground = false
    self.level = .screenSaver
    self.becomesKeyOnlyIfNeeded = true
    self.backgroundColor = .clear
    self.acceptsMouseMovedEvents = false
    self.hasShadow = false

    self.manager.window = self

    let rootView = rootView()
      .environmentObject(manager)
      .ignoresSafeArea()
      .padding()

    self.contentViewController = NSHostingController(rootView: rootView)

    setFrame(contentRect, display: false)

    NotificationCenter.default.addObserver(self, selector: #selector(screenChanged), name: NSApplication.didChangeScreenParametersNotification, object: nil)
  }

  @objc func screenChanged() {
    guard let screenFrame = NSScreen.main?.frame else { return }
    self.setFrame(screenFrame, display: true)
  }
}

