import AppKit
import Combine
import SwiftUI

@MainActor
final class BezelNotificationController {
  static let shared = BezelNotificationController()

  private var subscription: AnyCancellable?
  private var windowController: NSWindowController?
  private let subject = PassthroughSubject<BezelNotificationViewModel, Never>()

  lazy var coordinator = BezelNotificationCoordinator()

  private init() {
    self.subscription = subject
      .debounce(for: .seconds(1), scheduler: DispatchQueue.main)
      .sink { [weak self] _ in self?.clean() }
  }

  private func createWindowController() -> NSWindowController {
    let contentRect = NSScreen.main?.visibleFrame ?? .init(origin: .zero, size: .init(width: 200, height: 200))
    let content = BezelNotificationView(publisher: coordinator.publisher)
    let window = BezelNotificationWindow(contentRect: contentRect, content: content)
    window.setFrame(contentRect, display: false)
    let windowController = NSWindowController(window: window)
    return windowController
  }

  func post(_ notification: BezelNotificationViewModel) {
    if windowController == nil {
      windowController = createWindowController()
    }
    withAnimation(.easeOut(duration: 0.175)) {
      coordinator.publish(notification)
    }
    windowController?.showWindow(nil)
    subject.send(notification)
  }

  private func clean() {
    coordinator.publish(.init(id: UUID().uuidString, text: ""))
  }
}
