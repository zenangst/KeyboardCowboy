import AppKit
import Bonzai
import Combine
import KeyCodes
import MachPort
import SwiftUI

@MainActor
final class CapsuleNotificationWindow: NSObject, NSWindowDelegate {
  static let shared = CapsuleNotificationWindow()

  private lazy var publisher = CapsuleNotificationPublisher(text: "")
  private var window: (NSWindow & SizeFitting)?
  private var dismiss: DispatchWorkItem?
  private var subscription: AnyCancellable?

  private override init() {
    super.init()

    subscription = NotificationCenter.default
      .publisher(for: NSApplication.didChangeScreenParametersNotification)
      .sink { [weak self] _ in
        guard let window = self?.window, let screen = NSScreen.main else { return }
        let size = window.sizeThatFits(in: CGSize(width: screen.frame.width / 2,
                                                  height: screen.frame.height / 2))
        window.setSize(size, to: screen)
      }
  }

  func publish(_ text: String, state: CapsuleNotificationPublisher.State) {
    publisher.publish(text, state: state)

    dismiss?.cancel()

    let dismiss = DispatchWorkItem { [weak self] in
      self?.publisher.publish("", state: .idle)
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [window=self?.window] in
        window?.close()
      }
    }

    switch state {
    case .running, .idle: break
    case .failure, .success:
      self.dismiss = dismiss
      DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: dismiss)
    }
  }

  func open() {
    guard let screen = NSScreen.main else { return }

    window?.close()

    let styleMask: NSWindow.StyleMask = [.closable]
    let window = ZenSwiftUIWindow(contentRect: .zero, styleMask: styleMask) {
      CapsuleNotificationView(publisher: publisher)
    }

    let size = window.sizeThatFits(in: CGSize(width: screen.frame.width / 2,
                                              height: screen.frame.height / 2))
    window.setSize(size, to: screen)

    window.animationBehavior = .none
    window.backgroundColor = .clear
    window.delegate = self
    window.minSize = size
    window.titleVisibility = .hidden
    window.titlebarAppearsTransparent = true
    window.level = .statusBar
    window.orderFrontRegardless()

    publisher.publish("", state: .idle)

    self.window = window
  }

  func windowWillClose(_ notification: Notification) {
    self.window = nil
  }
}

private extension NSWindow {
  func setSize(_ size: CGSize, to screen: NSScreen) {
    let screenRect = screen.visibleFrame.mainDisplayFlipped
    setFrame(NSRect(origin: .init(x: screenRect.midX - size.width / 2,
                                  y: screenRect.midX / 4 + size.height),
                    size: size), display: false)
  }
}
