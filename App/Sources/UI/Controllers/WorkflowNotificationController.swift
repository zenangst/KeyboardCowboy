import AppKit
import Combine
import SwiftUI

final class WorkflowNotificationController {
  static let shared = WorkflowNotificationController()
  private static let emptyModel = WorkflowNotificationViewModel(
    id: UUID().uuidString,
    keyboardShortcuts: []
  )

  private var subscription: AnyCancellable?
  private var windowController: NSWindowController?
  private let subject = PassthroughSubject<WorkflowNotificationViewModel, Never>()
  @MainActor
  private let publisher: WorkflowNotificationPublisher = .init(WorkflowNotificationController.emptyModel)

  private init() {
    self.subscription = subject
      .debounce(for: .seconds(3), scheduler: DispatchQueue.main)
      .sink { [weak self] _ in self?.clean() }
  }

  private func createWorkflowWindow() -> NSWindowController {
    let contentRect = adjustFrame()
    let content = WorkflowNotificationView(publisher: publisher)
    let window = WorkflowNotificationWindow(contentRect: contentRect, content: content)
    window.layoutIfNeeded()
    let windowController = NSWindowController(window: window)
    windowController.loadWindow()
    window.setFrame(contentRect, display: false)


    return windowController
  }

  func post(_ notification: WorkflowNotificationViewModel) {
    Task { @MainActor in
      if windowController == nil {
        windowController = createWorkflowWindow()
      }

      withAnimation(WorkflowNotificationView.animation) {
        publisher.publish(notification)
      }

      let newFrame = adjustFrame()
      windowController?.window?.animator().setFrame(newFrame, display: true)
      windowController?.showWindow(nil)

      if notification.matches.isEmpty {
//        subject.send(notification)
      }
    }
  }

  private func adjustFrame() -> CGRect {
    guard let currentScreen = NSScreen.main,
          let mainDisplay = NSScreen.mainDisplay,
          let windowController,
          let window = windowController.window else { return .zero }
    let dockSize = getDockSize(currentScreen)
    let dockPosition = getDockPosition(currentScreen)
    let screenFrame = currentScreen.frame
    let width = max(window.frame.size.width, currentScreen.frame.width / 4)
    let height = max(window.frame.height, 64)
    let paddingOffset: CGFloat = 16
    let y: CGFloat

    if currentScreen == mainDisplay {
      y = CGFloat.formula(0) { fn in
        fn.add({ dockPosition == .bottom ? dockSize : 0 }())
      }
    } else {
      y = CGFloat.formula(mainDisplay.frame.maxY) { fn in
        fn.subtract(currentScreen.visibleFrame.origin.y)
        fn.subtract(height)
        fn.subtract(paddingOffset)
      }
    }

    let origin = CGPoint(x: screenFrame.maxX - width,
                         y: y)
    let size = CGSize(width: width, height: height)
    let newFrame = CGRect(origin: origin, size: size)

    return newFrame
  }

  private func clean() {
    Task { @MainActor in
      publisher.publish(WorkflowNotificationController.emptyModel)
    }
  }
}
