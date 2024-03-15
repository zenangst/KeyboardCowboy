import Cocoa
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
  private var didLaunch: Bool = false

  func applicationDidFinishLaunching(_ aNotification: Notification) {
    NSApp.appearance = NSAppearance(named: .darkAqua)
  }

  func applicationDidBecomeActive(_ notification: Notification) {
    guard didLaunch else {
      didLaunch = true
      return
    }
    NotificationCenter.default.post(.init(name: Notification.Name("OpenMainWindow")))
    KeyboardCowboy.activate()
  }
}
