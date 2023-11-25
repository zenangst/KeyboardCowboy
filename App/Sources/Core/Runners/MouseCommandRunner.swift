import AXEssibility
import AppKit
import CoreGraphics
import Foundation

class MouseCommandRunner {
  func run(_ command: MouseCommand, snapshot: UserSpace.Snapshot) async throws {
    guard let screen = NSScreen.main else { return }
    let source = CGEventSource(stateID: .hidSystemState)

    switch command.kind.element {
    case .focused:
      let systemElement = SystemAccessibilityElement()
      let focusedElement = try systemElement.focusedUIElement()

      print( try? focusedElement.value(.description, as: String.self) )
      print( try? focusedElement.value(.roleDescription, as: String.self) )

      switch command.kind {
      case .doubleClick:
        focusedElement.performAction(.press)
      case .click:
        focusedElement.performAction(.press)
      case .rightClick:
        focusedElement.performAction(.showMenu)
      }
    }
  }
}
