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
    let windowsCount = NSApplication.shared.windows.count
    guard windowsCount <= 1 else { return }
    openWindow?.openMainWindow()
  }
}
