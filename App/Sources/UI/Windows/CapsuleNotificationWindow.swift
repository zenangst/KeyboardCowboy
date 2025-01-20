import AppKit
import Bonzai
import KeyCodes
import MachPort
import SwiftUI

@MainActor
final class CapsuleNotificationWindow: NSObject, NSWindowDelegate {
  static let shared = CapsuleNotificationWindow()

  private lazy var publisher = CapsuleNotificationPublisher(text: "")
  private var window: NSWindow?
  private var dismiss: DispatchWorkItem?

  private override init() {
    super.init()
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

    let screenRect = screen.visibleFrame.mainDisplayFlipped

    window?.close()

    let styleMask: NSWindow.StyleMask = [.closable]
    let window = ZenSwiftUIWindow(contentRect: .zero, styleMask: styleMask) {
      CapsuleNotificationView(publisher: publisher)
    }

    let size = window.sizeThatFits(in: CGSize(width: screen.frame.width / 2,
                                              height: screen.frame.height / 2))

    window.setFrame(NSRect(origin: .init(x: screenRect.midX - size.width / 2,
                                         y: screenRect.midY / 2 - size.height),
                           size: size), display: false)

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
