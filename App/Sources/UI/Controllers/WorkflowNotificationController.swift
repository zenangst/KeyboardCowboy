import AppKit
import Combine
import SwiftUI

final class WorkflowNotificationController: ObservableObject {
  static let shared = WorkflowNotificationController()
  private static let emptyModel = WorkflowNotificationViewModel(
    id: UUID().uuidString,
    keyboardShortcuts: []
  )

  private var subscription: AnyCancellable?

  lazy var windowController: NSWindowController = {
    let contentRect = NSRect(origin: .zero, size: NSScreen.main?.frame.size ?? .zero)
    let content = WorkflowNotificationView(publisher: publisher)
    let window = NotificationWindow(contentRect: contentRect, content: content)
    window.layoutIfNeeded()
    let windowController = NSWindowController(window: window)
    windowController.loadWindow()
    window.setFrame(contentRect, display: false)
    return windowController
  }()

  @MainActor
  private let publisher: WorkflowNotificationPublisher = .init(WorkflowNotificationController.emptyModel)

  private init() { }

  func post(_ notification: WorkflowNotificationViewModel) {
    Task { @MainActor in
      withAnimation(WorkflowNotificationView.animation) {
        publisher.publish(notification)
      }
      windowController.showWindow(nil)
    }
  }
}
