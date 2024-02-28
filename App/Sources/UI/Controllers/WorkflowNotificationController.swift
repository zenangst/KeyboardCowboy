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

  private var workItem: DispatchWorkItem?

  lazy var windowController: NSWindowController = {
    let content = WorkflowNotificationView(publisher: publisher)
    let window = NotificationPanel(animationBehavior: .utilityWindow, content: content)
    let windowController = NSWindowController(window: window)
    return windowController
  }()

  private let publisher: WorkflowNotificationPublisher = .init(WorkflowNotificationController.emptyModel)

  private init() { }

  func cancelReset() {
    workItem?.cancel()
  }

  func reset() {
    workItem?.cancel()
    Task { @MainActor in
      WorkflowNotificationController.shared.post(
        WorkflowNotificationViewModel(
          id: UUID().uuidString,
          matches: [],
          glow: false,
          keyboardShortcuts: []), scheduleDismiss: false)
    }
  }

  func post(_ notification: WorkflowNotificationViewModel, scheduleDismiss: Bool) {
    guard notification != publisher.data else { return }

    workItem?.cancel()

    Task { @MainActor [publisher, windowController] in
      withAnimation(WorkflowNotificationView.animation) {
        publisher.publish(notification)
      }
      windowController.showWindow(nil)
    }

    guard scheduleDismiss else { return }

    workItem = DispatchWorkItem { [weak self] in
      self?.reset()
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: workItem!)
  }
}
