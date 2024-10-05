import DynamicNotchKit
import Foundation
import MachPort

@MainActor
final class KeyboardCleaner: ObservableObject {
  private var notchInfo: DynamicNotchInfo = DynamicNotchInfo(title: "")
  @Published var isEnabled: Bool = false {
    didSet {
      let title = isEnabled ? "Keyboard Cleaner enabled" : "Keyboard Cowboy disabled"
      notchInfo.setContent(title: title)
      notchInfo.show(for: 5.0)
    }
  }

  nonisolated init() {
    
  }

  func consumeEvent(_ event: MachPortEvent) -> Bool {
    switch event.type {
    case .keyUp, .keyDown:
      event.result = nil
      return true
      default:
      return false
    }
  }
}
