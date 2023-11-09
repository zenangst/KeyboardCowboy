import AppKit
import Combine
import SwiftUI

@MainActor
final class WorkflowNotificationController: ObservableObject {
  static let shared = WorkflowNotificationController()
  private static let emptyModel = WorkflowNotificationViewModel(
    id: UUID().uuidString,
    keyboardShortcuts: []
  )

  lazy var windowController: NSWindowController = {
    let content = WorkflowNotificationView(publisher: publisher)
    let window = NotificationWindow(animationBehavior: .utilityWindow, content: content)
    let windowController = NSWindowController(window: window)
    return windowController
  }()

  private let publisher: WorkflowNotificationPublisher = .init(WorkflowNotificationController.emptyModel)

  private init() { }

  func reset() {
    Task { @MainActor in
      WorkflowNotificationController.shared.post(.init(id: UUID().uuidString,
                                                       matches: [],
                                                       glow: false,
                                                       keyboardShortcuts: []))
    }
  }

  func post(_ notification: WorkflowNotificationViewModel) {
    Task { @MainActor [publisher, windowController] in
      withAnimation(WorkflowNotificationView.animation) {
        publisher.publish(notification)
      }
      windowController.showWindow(nil)
    }
  }
}
