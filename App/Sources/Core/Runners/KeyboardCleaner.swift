import AppKit
import DynamicNotchKit
import Foundation
import MachPort

@MainActor
final class KeyboardCleaner: ObservableObject {
  private lazy var notchInfo = DynamicNotchInfo(title: "") { KeyboardCleanerIcon(size: 24) }
  @Published var isEnabled: Bool = false {
    didSet {
      let title = isEnabled ? "Keyboard Cleaner enabled" : "Keyboard Cowboy disabled"
      notchInfo.setContent(title: title, iconView: KeyboardCleanerIcon(size: 36))
      notchInfo.show(on: NSScreen.main ?? NSScreen.screens[0], for: isEnabled ? 5.0 : 2.0)
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
