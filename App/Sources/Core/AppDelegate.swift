import AXEssibility
import Cocoa
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
  private var didLaunch: Bool = false
  var core: Core?

  func applicationDidFinishLaunching(_ aNotification: Notification) {
    NSApp.appearance = NSAppearance(named: .darkAqua)
  }

  func applicationDidBecomeActive(_ notification: Notification) {
    guard core?.contentStore.state == .initialized,
          AccessibilityPermission.shared.viewModel == .approved  else { return }

    guard didLaunch else {
      didLaunch = true
      return
    }

    NotificationCenter.default.post(.init(name: Notification.Name("OpenMainWindow")))
    KeyboardCowboy.activate()
  }
}
