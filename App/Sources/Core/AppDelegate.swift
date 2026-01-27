import AXEssibility
import Cocoa
@_exported import HotSwiftUI
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
//  var xpc: AnyObject?
  var openWindow: WindowOpener?

  // MARK: NSApplicationDelegate

  func applicationDidFinishLaunching(_: Notification) {
    Debugger.shared.log(.event, "Application launched")
    NSApp.appearance = NSAppearance(named: .darkAqua)

//    if #available(macOS 14.0, *) {
//      do {
//        let xpc = try LassoClient()
//        xpc.send("hello")
//        self.xpc = xpc
//      } catch let error {
//        print("error", error)
//      }
//    }
  }

  func applicationShouldHandleReopen(_: NSApplication, hasVisibleWindows: Bool) -> Bool {
    if !hasVisibleWindows {
      openWindow?.openMainWindow()
    }
    return true
  }
}
