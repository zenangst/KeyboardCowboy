import Cocoa
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
  func applicationDidFinishLaunching(_ aNotification: Notification) {
    NSApp.appearance = NSAppearance(named: .darkAqua)
  }

  func applicationDidBecomeActive(_ notification: Notification) {
    NotificationCenter.default.post(.init(name: Notification.Name("OpenMainWindow")))
    KeyboardCowboy.activate()
  }
}
