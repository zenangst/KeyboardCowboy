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
    let content = WorkflowNotificationView(publisher: publisher)
    let window = NotificationWindow(animationBehavior: .utilityWindow, content: content)
    let windowController = NSWindowController(window: window)
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
