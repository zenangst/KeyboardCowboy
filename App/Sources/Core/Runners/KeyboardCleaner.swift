import DynamicNotchKit
import Foundation
import MachPort

@MainActor
final class KeyboardCleaner: ObservableObject {
  private lazy var notchInfo = DynamicNotchInfo(iconView: KeyboardCleanerIcon(size: 24), title: "")
  @Published var isEnabled: Bool = false {
    didSet {
      let title = isEnabled ? "Keyboard Cleaner enabled" : "Keyboard Cowboy disabled"
      notchInfo.setContent(iconView: KeyboardCleanerIcon(size: 36), title: title)
      notchInfo.show(for: isEnabled ? 5.0 : 2.0)
    }
  }

  nonisolated init() { }

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
