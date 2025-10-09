import AppKit
import Bonzai
import Combine
import SwiftUI

@MainActor
final class WorkflowNotificationController: ObservableObject {
  static let shared = WorkflowNotificationController()
  private static let emptyModel = WorkflowNotificationViewModel(
    id: UUID().uuidString,
    keyboardShortcuts: [],
  )

  private var workItem: DispatchWorkItem?
  private var windowTask: Task<Void, any Error>?

  private lazy var window: SizeFittingWindow = {
    let styleMask: NSWindow.StyleMask = [.borderless, .nonactivatingPanel]
    let windowManager = WindowManager()
    let window = ZenSwiftUIWindow(
      styleMask: styleMask,
      content: WorkflowNotificationView(publisher: self.publisher)
        .environmentObject(windowManager)
        .ignoresSafeArea(),
    )
    windowManager.window = window

    window.animationBehavior = .utilityWindow
    window.collectionBehavior.insert(.fullScreenAuxiliary)
    window.collectionBehavior.insert(.canJoinAllSpaces)
    window.collectionBehavior.insert(.stationary)
    window.isOpaque = false
    window.isMovable = false
    window.isMovableByWindowBackground = false
    window.level = .screenSaver
    window.backgroundColor = .clear
    window.acceptsMouseMovedEvents = false
    window.ignoresMouseEvents = true
    window.hasShadow = false

    return window
  }()

  private let publisher: WorkflowNotificationPublisher = .init(WorkflowNotificationController.emptyModel)

  private init() {}

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
        keyboardShortcuts: [],
      )
      publisher.publish(emptyModel)
      window.close()
    }
  }

  func post(_ notification: WorkflowNotificationViewModel, scheduleDismiss: Bool) {
    guard notification != publisher.data else { return }

    workItem?.cancel()

    guard let screen = NSScreen.main else { return }

    let placementRawValue = UserDefaults.standard.string(forKey: "Notifications.Placement") ?? ""
    let placement = NotificationPlacement(rawValue: placementRawValue) ?? .bottomTrailing

    publisher.publish(notification)
    window.contentView?.layout()
    let size = window.sizeThatFits(in: CGSize(width: screen.frame.width / 2,
                                              height: screen.frame.height / 2))
    window.setFrame(NSRect(origin: .zero, size: size), display: false)

    let menubarHeight: CGFloat = 16
    let origin: NSPoint = switch placement {
    case .center:
      .init(x: screen.frame.midX, y: screen.frame.mainDisplayFlipped.midY)
    case .leading:
      .init(x: screen.frame.minX, y: screen.frame.mainDisplayFlipped.midY - size.height / 2)
    case .trailing:
      .init(x: screen.frame.maxX - size.width, y: screen.frame.mainDisplayFlipped.midY - size.height / 2)
    case .top:
      .init(x: screen.frame.midX - size.width / 2, y: screen.visibleFrame.mainDisplayFlipped.maxY - size.height - menubarHeight)
    case .bottom:
      .init(x: screen.frame.midX - size.width / 2, y: screen.frame.mainDisplayFlipped.minY)
    case .topLeading:
      .init(x: screen.frame.minX, y: screen.visibleFrame.mainDisplayFlipped.maxY - size.height - menubarHeight)
    case .topTrailing:
      .init(x: screen.frame.maxX - size.width, y: screen.frame.mainDisplayFlipped.maxY - size.height - menubarHeight)
    case .bottomLeading:
      .init(x: screen.frame.minX, y: screen.frame.mainDisplayFlipped.minY)
    case .bottomTrailing:
      .init(x: screen.frame.maxX - size.width, y: screen.frame.mainDisplayFlipped.minY)
    }

    window.setFrame(NSRect(origin: origin, size: size), display: true)
    window.orderFrontRegardless()

    guard scheduleDismiss else { return }

    workItem = DispatchWorkItem { [weak self] in
      self?.reset()
    }

    DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: workItem!)
  }
}
