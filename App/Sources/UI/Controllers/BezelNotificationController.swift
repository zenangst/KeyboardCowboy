import AppKit
import Combine
import SwiftUI

@MainActor
final class BezelNotificationController {
  static let shared = BezelNotificationController()

  lazy var windowController: NSWindowController = NSWindowController(window: window)

  lazy var window: NotificationPanel = {
    let content = BezelNotificationView(publisher: publisher)
    return NotificationPanel(animationBehavior: .none, content: content)
  }()

  private lazy var publisher = BezelNotificationPublisher(.init(id: UUID().uuidString, text: ""))
  private var subscription: AnyCancellable?

  private init() {
    Task { @MainActor in
      resizeAndAlignWindow(animate: false)
      windowController.showWindow(nil)

      subscription = NotificationCenter.default
        .publisher(for: NSApplication.didChangeScreenParametersNotification)
        .debounce(for: .milliseconds(250), scheduler: DispatchQueue.main)
        .sink { [weak self] _ in
          guard let self, window.contentView != nil else { return }
          self.resizeAndAlignWindow(animate: false)
        }
    }
  }

  @MainActor
  func post(_ notification: BezelNotificationViewModel) {
    guard window.contentView != nil else { return }
    withAnimation(.easeOut(duration: 0.175)) {
      publisher.publish(notification)
    }

    DispatchQueue.main.async {
      self.resizeAndAlignWindow(animate: true)
    }
  }

  private func resizeAndAlignWindow(animate: Bool) {
    guard let screen = NSScreen.main,
          let contentView = window.contentView else { return }
    let screenFrame = screen.frame
    let contentSize = contentView.intrinsicContentSize

    // Calculate the X coordinate for center alignment
    let newWindowOriginX = (screenFrame.width - contentSize.width) / 2.0 + screenFrame.minX

    // Calculate the Y coordinate for top alignment
    let newWindowOriginY = screenFrame.maxY - contentSize.height

    let newWindowFrame = CGRect(
      x: newWindowOriginX,
      y: newWindowOriginY,
      width: contentSize.width,
      height: contentSize.height
    )

    window.setFrame(newWindowFrame, display: true, animate: animate)
  }
}
