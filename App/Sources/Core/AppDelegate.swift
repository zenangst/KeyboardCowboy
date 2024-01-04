import Cocoa
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
  func applicationDidFinishLaunching(_ aNotification: Notification) {
    NSApp.appearance = NSAppearance(named: .darkAqua)
  }
}
