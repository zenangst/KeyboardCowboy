import AXEssibility
@preconcurrency import Inject
import Cocoa
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
//  var xpc: AnyObject?
  var openWindow: WindowOpener?

  // MARK: NSApplicationDelegate

  func applicationDidFinishLaunching(_ aNotification: Notification) {
    NSApp.appearance = NSAppearance(named: .darkAqua)
    InjectConfiguration.animation = .spring()

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

  func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows: Bool) -> Bool {
    if !hasVisibleWindows {
      openWindow?.openMainWindow()
    }
    return true
  }
}
