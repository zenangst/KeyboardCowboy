import AppKit
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

  private init() {
    Task { @MainActor in
      resizeAndAlignWindow(to: .init(width: 2, height: 2))
      windowController.showWindow(nil)
    }
  }

  @MainActor
  func post(_ notification: BezelNotificationViewModel) {
    guard let contentView = window.contentView else { return }
    withAnimation(.easeOut(duration: 0.175)) {
      publisher.publish(notification)
    }

    DispatchQueue.main.async {
      self.resizeAndAlignWindow(to: contentView.fittingSize)
    }
  }

  private func resizeAndAlignWindow(to contentSize: CGSize) {
    guard let screen = window.screen else { return }
    let screenFrame = screen.frame

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
    window.setFrame(newWindowFrame, display: true, animate: true)
  }
}
