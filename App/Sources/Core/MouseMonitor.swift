import Cocoa

@MainActor
final class MouseMonitor {
  private(set) var isDraggingUsingTheMouse: Bool = false
  private var monitor: Any?
  static var shared: MouseMonitor = .init()

  private init() { }

  func startMonitor() {
    monitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseUp, .leftMouseDragged]) { [weak self] event in
      guard let self = self else { return }

      switch event.type {
      case .leftMouseUp:
        self.isDraggingUsingTheMouse = false
      case .leftMouseDragged:
        self.isDraggingUsingTheMouse = true
      default:
        break
      }
    }
  }

  func stopMonitor() {
    guard let monitor = monitor else { return }
    NSEvent.removeMonitor(monitor)
    self.monitor = nil
  }
}
