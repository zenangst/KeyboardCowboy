import AppKit
import Combine
import SwiftUI

@MainActor
final class BezelNotificationController {
  static let shared = BezelNotificationController()

  lazy var windowController: NSWindowController = {
    let contentRect = NSScreen.main?.visibleFrame ?? .init(origin: .zero, size: .init(width: 200, height: 200))
    let content = BezelNotificationView(publisher: publisher)
    let window = NotificationWindow(contentRect: contentRect, content: content)
    window.setFrame(contentRect, display: false)
    let windowController = NSWindowController(window: window)
    return windowController
  }()
  private lazy var publisher = BezelNotificationPublisher(.init(id: UUID().uuidString, text: ""))

  private init() { }


  func post(_ notification: BezelNotificationViewModel) {
    withAnimation(.easeOut(duration: 0.175)) {
      publisher.publish(notification)
    }
    windowController.showWindow(nil)
  }
}
