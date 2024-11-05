import AppKit
import Bonzai
import Combine
import SwiftUI

@MainActor
final class UserModeWindow: NSObject, NSWindowDelegate {
  @MainActor
  static let shared = UserModeWindow()

  private var debouncer: DebounceManager<[UserMode]>?
  private var subscription: AnyCancellable?
  private var window: SizeFittingWindow?

  private override init() {
    super.init()
    debouncer = DebounceManager(for: .milliseconds(250)) { [weak self] userModes in
      self?.publish(userModes)
    }
    subscription = NotificationCenter.default
      .publisher(for: NSApplication.didChangeScreenParametersNotification)
      .sink { [weak self] _ in
        self?.repositionAndSize(self?.window)
      }
  }

  func show(_ userModes: [UserMode]) {
    cleanupUserModeWindows()

    if userModes.isEmpty {
      publish(userModes)
      window?.close()
      return
    }

    let content = CurrentUserModesView(publisher: UserSpace.shared.userModesPublisher)
    let styleMask: NSWindow.StyleMask = [.borderless, .nonactivatingPanel]
    let window = ZenSwiftUIWindow(styleMask: styleMask, content: content)
    window.identifier = .init(rawValue: KeyboardCowboyApp.userModeWindowIdentifier)
    window.animationBehavior = .documentWindow
    window.delegate = self
    window.collectionBehavior.insert(.fullScreenAuxiliary)
    window.collectionBehavior.insert(.canJoinAllSpaces)
    window.collectionBehavior.insert(.stationary)
    window.isOpaque = false
    window.isMovable = false
    window.isMovableByWindowBackground = false
    window.level = .screenSaver
    window.backgroundColor = .clear
    window.acceptsMouseMovedEvents = false
    window.ignoresMouseEvents = true
    window.hasShadow = false
    publish(userModes)
    repositionAndSize(window)
    window.orderFrontRegardless()
    self.window = window
  }

  // MARK: NSWindowDelegate

  func windowWillClose(_ notification: Notification) {
    self.window = nil
  }

  // MARK: Private methods

  private func cleanupUserModeWindows() {
    let identifier: NSUserInterfaceItemIdentifier = .init(rawValue: KeyboardCowboyApp.userModeWindowIdentifier)
    for window in NSApplication.shared.windows where window.identifier == identifier {
      window.close()
    }
  }

  private func repositionAndSize(_ window: SizeFittingWindow?) {
    guard let window, let screen = NSScreen.main else { return }
    window.contentView?.layout()
    let size = window.sizeThatFits(in: CGSize(width: 48, height: 48))
    let screenFrame = screen.frame.mainDisplayFlipped
    let x = screenFrame.maxX - size.width
    let y = screenFrame.minY
    let rect = NSRect(origin: NSPoint(x: x, y: y), size: size)

    window.setFrame(rect, display: false, animate: true)
  }

  private func publish(_ userModes: [UserMode]) {
    UserSpace.shared.userModesPublisher.publish(userModes)
  }
}
