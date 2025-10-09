import Cocoa

@MainActor
final class MouseMonitor {
  private(set) var isDraggingUsingTheMouse: Bool = false
  private var monitor: Any?
  static var shared: MouseMonitor = .init()

  private init() {}

  func startMonitor() {
    monitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseUp, .leftMouseDown]) { [weak self] event in
      guard let self else { return }

      isDraggingUsingTheMouse = switch event.type {
      case .leftMouseDown: true
      default: false
      }
    }
  }

  func stopMonitor() {
    guard let monitor else { return }

    NSEvent.removeMonitor(monitor)
    self.monitor = nil
    isDraggingUsingTheMouse = false
  }
}
