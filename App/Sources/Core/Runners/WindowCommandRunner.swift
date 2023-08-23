import AXEssibility
import Cocoa
import Foundation

final class WindowCommandRunner {
  @MainActor
  func run(_ command: WindowCommand) async throws {
    switch command.kind {
    case .center:
      try center()
    }
  }

  private func center() throws {
    guard let screen = NSScreen.main else { return }

    guard let frontmostApplication = NSWorkspace.shared.frontmostApplication else {
      return
    }

    let app = AppAccessibilityElement(frontmostApplication.processIdentifier)
    let window = try app.focusedWindow()

    guard let windowFrame = window.frame else { return }

    let screenFrame = screen.frame
    let x = screenFrame.midX - (windowFrame.width / 2)
    let y = screenFrame.midY - (windowFrame.height / 2)

    window.frame?.origin = .init(x: x, y: y)
  }
}
