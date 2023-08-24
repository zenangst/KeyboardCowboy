import AXEssibility
import Cocoa
import Foundation

enum WindowCommandRunnerError: Error {
  case unableToResolveFrontmostApplication
  case unabelToResolveWindowFrame
}

final class WindowCommandRunner {
  @MainActor
  func run(_ command: WindowCommand) async throws {
    switch command.kind {
    case .center:
      try center()
    case .moveToNextDisplay:
      try moveToNextDisplay()
    }
  }

  private func center(_ screen: NSScreen? = NSScreen.main) throws {
    guard let screen = screen else { return }

    let (window, windowFrame) = try getFocusedWindow()
    let screenFrame = screen.visibleFrame
    let x: Double = screenFrame.midX - (windowFrame.width / 2)
    let y: Double = (screenFrame.height / 2) - (windowFrame.height / 2)
    let origin: CGPoint = .init(x: x, y: y)

    print("screen.frame: \(screenFrame)")
    print("window.frame: \(windowFrame)")
    print("origin: \(origin)")

    window.frame?.origin = origin
  }

  private func moveToNextDisplay() throws {
    guard let mainScreen = NSScreen.main, 
          let nextScreen = NSScreen.screens.first(where: { $0.frame.origin.x > mainScreen.frame.origin.x }) else {
      return
    }
    let (window, frame) = try getFocusedWindow()

    window.frame?.origin.x = nextScreen.frame.origin.x
    try self.center(nextScreen)
  }

  private func getFocusedWindow() throws -> (WindowAccessibilityElement, CGRect) {
    guard let frontmostApplication = NSWorkspace.shared.frontmostApplication else {
      throw WindowCommandRunnerError.unableToResolveFrontmostApplication
    }

    let window = try AppAccessibilityElement(frontmostApplication.processIdentifier)
      .focusedWindow()

    guard let windowFrame = window.frame else {
      throw WindowCommandRunnerError.unabelToResolveWindowFrame
    }

    return (window, windowFrame)
  }
}
