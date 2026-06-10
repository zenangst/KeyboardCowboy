import Cocoa
import HotSwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
  func applicationDidFinishLaunching(_ notification: Notification) {
    NSApp.setActivationPolicy(.regular)
    NSApp.activate(ignoringOtherApps: true)
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(injected),
      name: NSNotification.Name(rawValue: "INJECTION_BUNDLE_NOTIFICATION"),
      object: nil,
    )
  }

  func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    true
  }

  @objc func injected() {}
}
