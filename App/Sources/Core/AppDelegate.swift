import AXEssibility
import Cocoa
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
  var openWindow: WindowOpener?

  // MARK: NSApplicationDelegate

  func applicationDidFinishLaunching(_ aNotification: Notification) {
    NSApp.appearance = NSAppearance(named: .darkAqua)
  }

  func applicationDidBecomeActive(_ notification: Notification) {
    openWindow?.openMainWindow()
  }
}
