import AXEssibility
import AppKit
import Foundation
import IOKit
import IOKit.graphics

final class WindowMoveWindowToNextDisplay {
  static func run(_ window: WindowAccessibilityElement, kind: WindowCommand.Mode) throws {
    guard let windowFrame = window.frame,
          let currentDisplay = NSScreen.screenIntersects(windowFrame.mainDisplayFlipped),
          let currentIndex = NSScreen.screens.firstIndex(of: currentDisplay) else { return }

    if NSScreen.screens.count == 1 {
      // Move to iPad if possible.
      if let axApp = AppAccessibilityElement.focusedApplication(),
         let menuItems = try? axApp.menuBar().menuItems().windowMenuBarItems,
         let moveToIPad = menuItems.first(where: { $0.identifier == "_toggleIPad:" }) {
        moveToIPad.performAction(.press)
      }
      return
    }

    let displays = NSScreen.screens
    let nextIndex = (currentIndex + 1) % displays.count
    let nextDisplay = displays[nextIndex]

    moveWindowToNextDisplay(window, to: nextDisplay, from: currentDisplay)
  }

  static func moveWindowToNextDisplay(_ window: WindowAccessibilityElement, to screen: NSScreen, from currentScreen: NSScreen) {
    // Get the current window's frame
    guard let windowFrame = window.frame else { return }

    let currentScreenFrame = currentScreen.frame.mainDisplayFlipped
    let targetScreenFrame = screen.frame.mainDisplayFlipped

    // Calculate the relative position and size
    let relativeOriginX = (windowFrame.origin.x - currentScreenFrame.origin.x) / currentScreenFrame.width
    let relativeOriginY = (windowFrame.origin.y - currentScreenFrame.origin.y) / currentScreenFrame.height
    let relativeWidth = windowFrame.width / currentScreenFrame.width
    let relativeHeight = windowFrame.height / currentScreenFrame.height

    // Calculate the new position and size on the target screen
    let newOriginX = targetScreenFrame.origin.x + relativeOriginX * targetScreenFrame.width
    let newOriginY = targetScreenFrame.origin.y + relativeOriginY * targetScreenFrame.height
    let newWidth = relativeWidth * targetScreenFrame.width
    let newHeight = relativeHeight * targetScreenFrame.height

    // Ensure the new frame is within the target screen's visible frame
    let newFrame = CGRect(x: newOriginX, y: newOriginY, width: newWidth, height: newHeight)

    // Set the new frame using the window's accessibility element
    window.frame = newFrame
  }
}
