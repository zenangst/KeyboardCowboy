import AXEssibility
import Cocoa
import Combine
import Foundation
import Windows

enum WindowFocusFrontmostWindow {
  static func run(kind: WindowFocusCommand.Kind, snapshot: UserSpace.Snapshot) {
    var frontmostIndex = 0
    let windows = snapshot.windows.frontmostApplicationWindows
    let frontmostApplication = snapshot.frontMostApplication
    let frontmostAppElement = AppAccessibilityElement(frontmostApplication.ref.processIdentifier)
    if let focusedWindow = try? frontmostAppElement.focusedWindow(),
       let index = windows.firstIndex(where: { $0.id == focusedWindow.id }){
      frontmostIndex = index
    }

    guard !windows.isEmpty else {
      CustomSystemRoutine(rawValue: snapshot.frontMostApplication.bundleIdentifier)?
        .routine(snapshot.frontMostApplication)
        .run(kind)
      return
    }

    if case .moveFocusToNextWindowFront = kind {
      frontmostIndex += 1
      if frontmostIndex >= windows.count {
        frontmostIndex = 0
      }
    } else {
      frontmostIndex -= 1
      if frontmostIndex < 0 {
        frontmostIndex = windows.count - 1
      }
    }

    let window = windows[frontmostIndex]
    window.performAction(.raise)
  }

}
