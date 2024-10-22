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

  private var subscription: AnyCancellable?
  private var passthrough: PassthroughSubject<(WorkflowNotificationViewModel, Bool), Never> = .init()
  private var workItem: DispatchWorkItem?
  private var windowTask: Task<Void, any Error>?

  lazy var window: NSWindow = {
    let content = WorkflowNotificationView(publisher: publisher)
    return NotificationPanel(animationBehavior: .utilityWindow, content: content)
  }()

  private let publisher: WorkflowNotificationPublisher = .init(WorkflowNotificationController.emptyModel)

  private init() {
    subscription = passthrough
      .debounce(for: .seconds(0.05), scheduler: RunLoop.main)
      .sink { [weak self] (notification, scheduleDismiss) in
      self?.passthrough(notification, scheduleDismiss: scheduleDismiss)
    }
  }

  func cancelReset() {
    workItem?.cancel()
  }

  func reset() {
    windowTask?.cancel()
    workItem?.cancel()
    Task { @MainActor in
      let emptyModel = WorkflowNotificationViewModel(
        id: UUID().uuidString,
        matches: [],
        glow: false,
        keyboardShortcuts: [])
      publisher.publish(emptyModel)
      window.close()
    }
  }

  func post(_ notification: WorkflowNotificationViewModel, scheduleDismiss: Bool) {
    passthrough.send((notification, scheduleDismiss))
  }

  private func passthrough(_ notification: WorkflowNotificationViewModel, scheduleDismiss: Bool) {
    guard notification != publisher.data else { return }

    workItem?.cancel()
    windowTask?.cancel()
    windowTask = Task { @MainActor [publisher] in
      try Task.checkCancellation()

      guard let screen = NSScreen.main else { return }
      let windowRect = screen.visibleFrame

      withAnimation(WorkflowNotificationView.animation) {
        window.setFrame(windowRect, display: true, animate: true)
        window.orderFrontRegardless()
        publisher.publish(notification)
      }
    }

    guard scheduleDismiss else { return }

    workItem = DispatchWorkItem { [weak self] in
      self?.reset()
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: workItem!)
  }
}
