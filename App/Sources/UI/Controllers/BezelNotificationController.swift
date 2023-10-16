import AppKit
import Combine
import SwiftUI

@MainActor
final class BezelNotificationController {
  static let shared = BezelNotificationController()

  lazy var windowController: NSWindowController = {
    let content = BezelNotificationView(publisher: publisher)
    let window = NotificationWindow(animationBehavior: .alertPanel, content: content)
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
