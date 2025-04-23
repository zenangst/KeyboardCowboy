import AppKit
import DynamicNotchKit
import Foundation
import MachPort
import SwiftUI

@MainActor
final class KeyboardCleaner: ObservableObject {

  private lazy var notchInfo = DynamicNotchInfo.init(icon: .init(content: { KeyboardCleanerIcon(size: 24) }), title: "")
  @Published var isEnabled: Bool = false {
    didSet {
      let title = isEnabled ? "Keyboard Cleaner enabled" : "Keyboard Cowboy disabled"
      notchInfo.title = LocalizedStringKey(stringLiteral: title)
      notchInfo.icon = .init { KeyboardCleanerIcon(size: 36) }
      Task {
        await notchInfo.expand(on: NSScreen.main ?? NSScreen.screens[0])
        try await Task.sleep(for: .seconds(2))
        await notchInfo.hide()
      }
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
