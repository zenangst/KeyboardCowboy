import AXEssibility
import Cocoa
import Combine
import Foundation
import Windows

enum SystemFrontmostWindowFocus {
  static func run(kind: SystemCommand.Kind, snapshot: UserSpace.Snapshot) {
    var frontMostIndex = 0
    let windows = snapshot.windows.frontMostApplicationWindows
    let frontMostApplication = snapshot.frontMostApplication
    let frontMostAppElement = AppAccessibilityElement(frontMostApplication.ref.processIdentifier)
    if let focusedWindow = try? frontMostAppElement.focusedWindow(),
       let index = windows.firstIndex(where: { $0.id == focusedWindow.id }){
      frontMostIndex = index
    }

    guard !windows.isEmpty else {
      CustomSystemRoutine(rawValue: snapshot.frontMostApplication.bundleIdentifier)?
        .routine(snapshot.frontMostApplication)
        .run(kind)
      return
    }

    if case .moveFocusToNextWindowFront = kind {
      frontMostIndex += 1
      if frontMostIndex >= windows.count {
        frontMostIndex = 0
      }
    } else {
      frontMostIndex -= 1
      if frontMostIndex < 0 {
        frontMostIndex = windows.count - 1
      }
    }

    let window = windows[frontMostIndex]
    window.performAction(.raise)
  }
}
