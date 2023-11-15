import AXEssibility
import Cocoa
import Combine
import Foundation
import Windows

enum SystemFrontmostWindowFocus {
  static func run(_ frontMostIndex: inout Int, kind: SystemCommand.Kind, snapshot: UserSpace.Snapshot) {
    guard !snapshot.windows.frontMostApplicationWindows.isEmpty else {
      CustomSystemRoutine(rawValue: snapshot.frontMostApplication.bundleIdentifier)?
        .routine(snapshot.frontMostApplication)
        .run(kind)
      return
    }
    if case .moveFocusToNextWindowFront = kind {
      frontMostIndex += 1
      if frontMostIndex >= snapshot.windows.frontMostApplicationWindows.count {
        frontMostIndex = 0
      }
    } else {
      frontMostIndex -= 1
      if frontMostIndex < 0 {
        frontMostIndex = snapshot.windows.frontMostApplicationWindows.count - 1
      }
    }

    let window = snapshot.windows.frontMostApplicationWindows[frontMostIndex]
    window.performAction(.raise)
  }
}
