import Cocoa
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
  func applicationDidFinishLaunching(_ aNotification: Notification) {
    NSApp.appearance = NSAppearance(named: .darkAqua)
    switch KeyboardCowboy.env {
    case .previews:
      break
    case .development:
      KeyboardCowboy.activate()
    case .production:
      KeyboardCowboy.mainWindow?.close()
    }
  }
}
